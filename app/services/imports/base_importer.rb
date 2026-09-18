module Imports
  # Shared behaviour for platform importers. Subclasses implement #import_items
  # and build unsaved Post/Page records, then hand them to #save_item.
  #
  # Each item is saved exactly once, with its content, featured image and
  # taxonomy already set. That keeps imports silent: Post::Publishable only
  # notifies subscribers from publish!, and Post::Webhookable/Versionable only
  # react to updates — don't split an import into create-then-update. Remote
  # media is downloaded *before* the item's transaction so SQLite's write lock
  # is never held across an HTTP request.
  #
  # Items whose slug already exists are skipped, so re-running an import is safe.
  class BaseImporter
    def initialize(io:, user:, site_url: nil, downloader: MediaDownloader.new)
      @io = io
      @user = user
      @site_url = site_url.presence
      @downloader = downloader
      @stats = Hash.new(0)
      @warnings = []
    end

    # Returns a stats hash (string keys) suitable for Import#stats.
    def call
      import_items
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

    def import_items
      raise NotImplementedError
    end

    # Returns true when the record may be imported; otherwise counts it as
    # skipped with a warning.
    def importable_slug?(model, slug, title)
      if model == Page && Page::RESERVED_SLUGS.include?(slug)
        warn("Skipped page \"#{title}\": the slug \"#{slug}\" is reserved in Prose")
      elsif model.exists?(slug: slug)
        warn("Skipped \"#{title}\": an item with the same slug already exists")
      else
        return true
      end

      @stats["skipped"] += 1
      false
    end

    # Confines an unexpected failure (odd markup crashing the converter, a
    # storage error attaching an image) to the item it happened on, so the rest
    # of the import still lands. Reading/parsing the export happens outside
    # this and still fails the whole import.
    def import_item(title)
      yield
    rescue StandardError => e
      Rails.logger.error("[#{self.class.name}] #{title}: #{e.class}: #{e.message}")
      warn("Could not import \"#{title}\": #{e.class}: #{e.message.to_s.truncate(200)}")
      @stats["failed"] += 1
    end

    def save_item(record, title, counter)
      ActiveRecord::Base.transaction do
        yield if block_given?
        record.save!
      end
      @stats[counter] += 1
    rescue ActiveRecord::RecordInvalid => e
      warn("Could not import \"#{title}\": #{e.record.errors.full_messages.to_sentence}")
      @stats["failed"] += 1
    end

    def attach_featured_image(post, url)
      return if url.blank?

      blob = @downloader.download(url)
      if blob
        post.featured_image.attach(blob)
      else
        warn("#{post.title}: could not download featured image #{url.truncate(80)}")
      end
    end

    def find_or_create_category(name, slug = nil)
      slug = slug.to_s.parameterize.presence || name.parameterize
      Category.find_by(slug: slug) || Category.find_by(name: name) || Category.create!(name: name, slug: slug)
    end

    def find_or_create_tag(name, slug = nil)
      slug = slug.to_s.parameterize.presence || name.parameterize
      Tag.find_by(slug: slug) || Tag.find_by(name: name) || Tag.create!(name: name, slug: slug)
    end

    # Future-dated scheduled items stay scheduled; ones whose date has passed
    # are published so Publishable's future validation doesn't reject them.
    def resolve_schedule(status, published_at)
      return :published if status == :scheduled && published_at <= Time.current

      status
    end

    def plain_text(html, length:)
      ActionController::Base.helpers.strip_tags(html.to_s).to_s.squish.truncate(length).presence
    end

    # Downloaded blobs end up unattached when their item failed to save or was
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
