module Imports
  # Imports posts and pages from a WordPress WXR export. See BaseImporter for
  # the save-once / skip-duplicates contract.
  class WordpressImporter < BaseImporter
    POST_STATUSES = { "publish" => :published, "future" => :scheduled, "draft" => :draft, "pending" => :draft, "private" => :draft }.freeze
    PAGE_STATUSES = { "publish" => :published, "draft" => :draft, "pending" => :draft, "private" => :draft, "future" => :draft }.freeze
    UNCATEGORIZED = "uncategorized".freeze

    private

    def import_items
      parser = Wordpress::WxrParser.new(@io)
      @converter = Wordpress::ContentConverter.new(downloader: @downloader, site_url: @site_url || parser.site_url, warn: method(:warn))

      parser.items.each do |item|
        import_item(title_for(item)) do
          item.post_type == "page" ? import_page(item) : import_post(item)
        end
      end
    end

    def import_post(item)
      status = POST_STATUSES[item.status]
      return @stats["skipped"] += 1 unless status

      title = title_for(item)
      slug = slug_for(item, title)
      return unless importable_slug?(Post, slug, title)

      published_at = item.published_at || Time.current
      status = resolve_schedule(status, published_at)

      post = Post.new(
        title: title,
        slug: slug,
        user: @user,
        status: status,
        published_at: status == :draft ? nil : published_at,
        meta_description: plain_text(item.excerpt, length: 160),
        content: @converter.convert(item.content, title: title)
      )
      attach_featured_image(post, item.featured_image_url)

      save_item(post, title, "posts_imported") do
        categories = item.categories.reject { |term| term.slug == UNCATEGORIZED }
        post.category = find_or_create_category(categories.first.name, categories.first.slug) if categories.any?
        post.tags = (categories.drop(1) + item.tags).uniq { |term| term.name.downcase }.map { |term| find_or_create_tag(term.name, term.slug) }
      end
    end

    def import_page(item)
      status = PAGE_STATUSES[item.status]
      return @stats["skipped"] += 1 unless status

      title = title_for(item)
      slug = slug_for(item, title)
      return unless importable_slug?(Page, slug, title)

      page = Page.new(
        title: title,
        slug: slug,
        user: @user,
        status: status,
        published_at: status == :published ? (item.published_at || Time.current) : nil,
        position: item.menu_order,
        content: @converter.convert(item.content, title: title)
      )

      save_item(page, title, "pages_imported")
    end

    def title_for(item)
      item.title.presence || "Untitled"
    end

    # WordPress slugs can be percent-encoded Unicode; Prose slugs are ASCII.
    def slug_for(item, title)
      item.slug.parameterize.presence || title.parameterize.presence || "wordpress-#{item.wp_id}"
    end
  end
end
