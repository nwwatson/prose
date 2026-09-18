module Exports
  # Builds a full-site JSON backup: settings, authors, taxonomy, posts, pages,
  # navigation, and subscribers. Rich text is exported as HTML so nothing is
  # lost in conversion.
  #
  # Site settings use an explicit allowlist (SITE_SETTING_ATTRIBUTES) rather
  # than excluding known secrets, so a newly added API key column is never
  # exported by accident. Password digests and subscriber auth tokens are
  # never included.
  class JsonExporter
    FORMAT_VERSION = 1

    SITE_SETTING_ATTRIBUTES = %w[
      site_name site_description locale theme_mode block_crawlers
      heading_font subtitle_font body_font heading_font_size subtitle_font_size body_font_size
      background_color dark_theme dark_bg_color dark_text_color dark_accent_color
      email_provider email_accent_color email_background_color email_body_text_color email_heading_color
      email_font_family email_footer_text email_preheader_text email_default_template
      email_social_twitter email_social_github email_social_linkedin email_social_website
      ai_model ai_max_tokens image_model payments_currency
    ].freeze

    def self.call
      new.call
    end

    # Returns a rewound Tempfile containing the JSON document. The caller owns
    # the file and should close! it once it has been attached.
    def call
      tempfile = Tempfile.new([ "prose-json-export", ".json" ])
      tempfile.write(JSON.pretty_generate(as_json))
      tempfile.rewind
      tempfile
    end

    def as_json
      {
        format: "prose",
        version: FORMAT_VERSION,
        exported_at: Time.current.iso8601,
        site: site,
        authors: authors,
        categories: categories,
        tags: tags,
        posts: posts,
        pages: pages,
        navigation_items: navigation_items,
        subscriber_labels: subscriber_labels,
        subscribers: subscribers
      }
    end

    private

    def site
      SiteSetting.current.attributes.slice(*SITE_SETTING_ATTRIBUTES)
    end

    def navigation_items
      NavigationItem.order(:location, :position, :id).map do |item|
        item.slice(:label, :url, :location, :position, :open_in_new_tab)
      end
    end

    def authors
      User.includes(:identity).order(:id).map do |user|
        identity = user.identity
        {
          id: user.id,
          email: user.email,
          role: user.role,
          name: identity&.name,
          handle: identity&.handle,
          bio: identity&.bio,
          website_url: identity&.website_url,
          twitter_handle: identity&.twitter_handle,
          github_handle: identity&.github_handle,
          created_at: user.created_at.iso8601
        }
      end
    end

    def categories
      Category.ordered.map do |category|
        category.slice(:id, :name, :slug, :description, :position)
      end
    end

    def tags
      Tag.order(:name).map { |tag| tag.slice(:id, :name, :slug) }
    end

    def posts
      Post.includes(:tags, :rich_text_content, featured_image_attachment: :blob).order(:id).map do |post|
        post.slice(:id, :title, :subtitle, :slug, :status, :visibility, :featured, :show_toc,
                   :meta_description, :category_id, :user_id).merge(
          published_at: post.published_at&.iso8601,
          created_at: post.created_at.iso8601,
          updated_at: post.updated_at.iso8601,
          tag_ids: post.tags.map(&:id).sort,
          featured_image: post.featured_image.attached? ? post.featured_image.filename.to_s : nil,
          content_html: post.content&.body&.to_html.to_s
        )
      end
    end

    def pages
      Page.includes(:rich_text_content).order(:id).map do |page|
        page.slice(:id, :title, :slug, :status, :meta_description, :user_id).merge(
          published_at: page.published_at&.iso8601,
          created_at: page.created_at.iso8601,
          updated_at: page.updated_at.iso8601,
          content_html: page.content&.body&.to_html.to_s
        )
      end
    end

    def subscriber_labels
      SubscriberLabel.order(:name).map { |label| label.slice(:id, :name, :color) }
    end

    def subscribers
      Subscriber.includes(:subscriber_labelings).order(:id).map do |subscriber|
        {
          id: subscriber.id,
          email: subscriber.email,
          confirmed_at: subscriber.confirmed_at&.iso8601,
          unsubscribed_at: subscriber.unsubscribed_at&.iso8601,
          email_frequency: subscriber.email_frequency,
          created_at: subscriber.created_at.iso8601,
          label_ids: subscriber.subscriber_labelings.map(&:subscriber_label_id).sort
        }
      end
    end
  end
end
