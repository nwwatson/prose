module Imports
  # Imports posts and pages from a WordPress WXR export.
  #
  # Each item is saved exactly once, with its content, featured image, category
  # and tags already set. That keeps imports silent: Post::Publishable only
  # notifies subscribers from publish!, and Post::Webhookable/Versionable only
  # react to updates. Remote media is downloaded *before* the item's
  # transaction so SQLite's write lock is never held across an HTTP request.
  #
  # Items whose slug already exists are skipped, so re-running an import is safe.
  class WordpressImporter
    POST_STATUSES = { "publish" => :published, "future" => :scheduled, "draft" => :draft, "pending" => :draft, "private" => :draft }.freeze
    PAGE_STATUSES = { "publish" => :published, "draft" => :draft, "pending" => :draft, "private" => :draft, "future" => :draft }.freeze
    UNCATEGORIZED = "uncategorized".freeze

    def initialize(io:, user:, downloader: MediaDownloader.new)
      @io = io
      @user = user
      @downloader = downloader
      @stats = Hash.new(0)
      @warnings = []
    end

    # Returns a stats hash (string keys) suitable for Import#stats.
    def call
      parser = Wordpress::WxrParser.new(@io)
      @converter = Wordpress::ContentConverter.new(downloader: @downloader, site_url: parser.site_url, warn: method(:warn))

      parser.items.each do |item|
        import_item(title_for(item)) do
          item.post_type == "page" ? import_page(item) : import_post(item)
        end
      end

      purge_unused_blobs
      result
    end

    def result
      @stats.merge(
        "media_downloaded" => @downloader.try(:created_blobs).to_a.size,
        "media_failed" => @downloader.try(:failures).to_a.size,
        "warnings" => @warnings.first(Import::MAX_WARNINGS),
        "warnings_truncated" => [ @warnings.size - Import::MAX_WARNINGS, 0 ].max
      ).transform_keys(&:to_s)
    end

    private

    def import_post(item)
      status = POST_STATUSES[item.status]
      return @stats["skipped"] += 1 unless status

      title = title_for(item)
      slug = slug_for(item, title)
      return skip_duplicate(title) if Post.exists?(slug: slug)

      published_at = item.published_at || Time.current
      status = :published if status == :scheduled && published_at <= Time.current

      post = Post.new(
        title: title,
        slug: slug,
        user: @user,
        status: status,
        published_at: status == :draft ? nil : published_at,
        meta_description: meta_description_for(item),
        content: @converter.convert(item.content, title: title)
      )
      attach_featured_image(post, item)

      save_item(post, title) do
        categories = item.categories.reject { |term| term.slug == UNCATEGORIZED }
        post.category = find_or_create_category(categories.first) if categories.any?
        post.tags = (categories.drop(1) + item.tags).uniq { |term| term.name.downcase }.map { |term| find_or_create_tag(term) }
      end
      @stats["posts_imported"] += 1 if post.persisted?
    end

    def import_page(item)
      status = PAGE_STATUSES[item.status]
      return @stats["skipped"] += 1 unless status

      title = title_for(item)
      slug = slug_for(item, title)
      if Page::RESERVED_SLUGS.include?(slug)
        warn("Skipped page \"#{title}\": the slug \"#{slug}\" is reserved in Prose")
        return @stats["skipped"] += 1
      end
      return skip_duplicate(title) if Page.exists?(slug: slug)

      page = Page.new(
        title: title,
        slug: slug,
        user: @user,
        status: status,
        published_at: status == :published ? (item.published_at || Time.current) : nil,
        position: item.menu_order,
        content: @converter.convert(item.content, title: title)
      )

      save_item(page, title)
      @stats["pages_imported"] += 1 if page.persisted?
    end

    # Confines an unexpected failure (bad markup crashing the converter, a
    # storage error attaching an image) to the item it happened on: the import
    # continues with the rest. Failures while reading the export file itself
    # happen outside this and still fail the whole import.
    def import_item(title)
      yield
    rescue StandardError => e
      Rails.logger.error("[Imports::WordpressImporter] #{title}: #{e.class}: #{e.message}")
      warn("Could not import \"#{title}\": #{e.class}: #{e.message.to_s.truncate(200)}")
      @stats["failed"] += 1
    end

    def save_item(record, title)
      ActiveRecord::Base.transaction do
        yield if block_given?
        record.save!
      end
    rescue ActiveRecord::RecordInvalid => e
      warn("Could not import \"#{title}\": #{e.record.errors.full_messages.to_sentence}")
      @stats["failed"] += 1
    end

    def attach_featured_image(post, item)
      return if item.featured_image_url.blank?

      blob = @downloader.download(item.featured_image_url)
      if blob
        post.featured_image.attach(blob)
      else
        warn("#{post.title}: could not download featured image #{item.featured_image_url.truncate(80)}")
      end
    end

    def find_or_create_category(term)
      slug = term.slug.parameterize.presence || term.name.parameterize
      Category.find_by(slug: slug) || Category.find_by(name: term.name) || Category.create!(name: term.name, slug: slug)
    end

    def find_or_create_tag(term)
      slug = term.slug.parameterize.presence || term.name.parameterize
      Tag.find_by(slug: slug) || Tag.find_by(name: term.name) || Tag.create!(name: term.name, slug: slug)
    end

    def title_for(item)
      item.title.presence || "Untitled"
    end

    # WordPress slugs can be percent-encoded Unicode; Prose slugs are ASCII.
    def slug_for(item, title)
      item.slug.parameterize.presence || title.parameterize.presence || "wordpress-#{item.wp_id}"
    end

    def meta_description_for(item)
      ActionController::Base.helpers.strip_tags(item.excerpt).to_s.squish.truncate(160).presence
    end

    def skip_duplicate(title)
      warn("Skipped \"#{title}\": an item with the same slug already exists")
      @stats["skipped"] += 1
    end

    # Downloaded blobs end up unattached when their post failed to save or was
    # a duplicate; don't leave them orphaned in storage.
    def purge_unused_blobs
      @downloader.try(:created_blobs).to_a.each do |blob|
        blob.purge_later unless blob.attachments.exists?
      end
    end

    def warn(message)
      @warnings << message
    end
  end
end
