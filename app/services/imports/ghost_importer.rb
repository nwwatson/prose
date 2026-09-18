module Imports
  # Imports posts and pages from a Ghost JSON export. See BaseImporter for the
  # save-once / skip-duplicates contract.
  #
  # Ghost has no categories, so a post's primary (first public) tag becomes its
  # category and every public tag becomes a tag. "sent" posts were email-only
  # newsletters that never appeared on the site, so they import as drafts.
  class GhostImporter < BaseImporter
    POST_STATUSES = { "published" => :published, "scheduled" => :scheduled, "draft" => :draft, "sent" => :draft }.freeze
    PAGE_STATUSES = { "published" => :published, "scheduled" => :draft, "draft" => :draft }.freeze
    VISIBILITIES = { "public" => :public, "members" => :members_only, "paid" => :paid_only, "tiers" => :paid_only }.freeze

    private

    def import_items
      parser = Ghost::ExportParser.new(@io)
      @converter = Ghost::ContentConverter.new(downloader: @downloader, site_url: @site_url, warn: method(:warn))
      @warned_missing_site_url = false

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
      warn("#{title}: email-only (sent) post imported as a draft") if item.status == "sent"

      post = Post.new(
        title: title,
        subtitle: item.custom_excerpt.to_s.squish.presence,
        slug: slug,
        user: @user,
        status: status,
        visibility: VISIBILITIES.fetch(item.visibility, :public),
        featured: item.featured,
        published_at: status == :draft ? nil : published_at,
        meta_description: plain_text(item.meta_description, length: 160),
        content: convert(item, title)
      )
      attach_featured_image(post, resolve_placeholder(item.feature_image))

      save_item(post, title, "posts_imported") do
        post.category = find_or_create_category(item.tags.first.name, item.tags.first.slug) if item.tags.any?
        post.tags = item.tags.uniq { |tag| tag.name.downcase }.map { |tag| find_or_create_tag(tag.name, tag.slug) }
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
        meta_description: plain_text(item.meta_description, length: 160),
        content: convert(item, title)
      )

      save_item(page, title, "pages_imported")
    end

    def convert(item, title)
      warn("#{title}: no HTML in export; imported plain text only") if item.content_source == :plaintext
      item.unsupported_cards.each { |card| warn("#{title}: removed unsupported #{card} card") }
      warn_missing_site_url if item.content.include?(Ghost::ContentConverter::PLACEHOLDER)

      @converter.convert(item.content, title: title)
    end

    def resolve_placeholder(url)
      return if url.blank?

      warn_missing_site_url if url.include?(Ghost::ContentConverter::PLACEHOLDER)
      url.sub(Ghost::ContentConverter::PLACEHOLDER, @site_url.to_s.chomp("/"))
    end

    def warn_missing_site_url
      return if @site_url || @warned_missing_site_url

      @warned_missing_site_url = true
      warn("No Ghost site URL was given, so images hosted on the Ghost site could not be downloaded")
    end

    def title_for(item)
      item.title.presence || "Untitled"
    end

    def slug_for(item, title)
      item.slug.parameterize.presence || title.parameterize.presence || "ghost-#{item.ghost_id}"
    end
  end
end
