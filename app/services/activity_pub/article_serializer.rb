module ActivityPub
  # Serializes a Post as an ActivityStreams Article. Public posts carry their
  # full HTML; members-only and paid posts carry only a teaser and a link, so
  # gated content never leaves the site.
  module ArticleSerializer
    CONTEXT = "https://www.w3.org/ns/activitystreams".freeze

    module_function

    def call(post, with_context: true)
      url = Urls.post_url(post)
      {
        "@context" => (CONTEXT if with_context),
        "id" => url,
        "type" => "Article",
        "attributedTo" => Urls.actor_url,
        "name" => post.title,
        "summary" => post.subtitle.presence && ERB::Util.html_escape(post.subtitle),
        "content" => content_html(post, url),
        "mediaType" => "text/html",
        "url" => url,
        "published" => post.published_at&.iso8601,
        "updated" => post.updated_at.iso8601,
        "to" => [ Urls::PUBLIC_COLLECTION ],
        "cc" => [ Urls.followers_url ],
        "tag" => post.tags.map { |tag| { "type" => "Hashtag", "name" => "##{tag.name.delete(" ")}", "href" => Urls.tag_url(tag) } },
        "attachment" => attachments(post)
      }.compact
    end

    def content_html(post, url)
      if post.visibility_public?
        absolutize(full_html(post))
      else
        helpers = ActionController::Base.helpers
        teaser = helpers.tag.p(post.seo_description)
        link = helpers.tag.p(helpers.link_to(I18n.t("activity_pub.read_more", site: SiteSetting.current.site_name), url))
        teaser + link
      end
    end

    def full_html(post)
      return "" if post.content.blank?

      RichTextFlattener.call(post.content.body, wrap: false) { |blob| Urls.blob_url(blob) }
    end

    def absolutize(html)
      fragment = Nokogiri::HTML5.fragment(html)
      fragment.css("[href], [src]").each do |node|
        %w[href src].each { |attr| node[attr] = Urls.absolute(node[attr]) if node[attr] }
      end
      fragment.to_html
    end

    def attachments(post)
      return [] unless post.featured_image.attached?

      [ { "type" => "Image", "mediaType" => post.featured_image.content_type, "url" => Urls.blob_url(post.featured_image), "name" => post.title } ]
    end
  end
end
