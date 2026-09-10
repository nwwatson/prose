module MetaTagsHelper
  def page_title(title = nil)
    if title.present?
      "#{title} — #{site_name}"
    else
      site_name
    end
  end

  # Emits the full SEO <head> sequence for a page: description, Open Graph,
  # Twitter card, canonical link and (optionally) a JSON-LD block. The image is
  # resolved once and shared by the OG and Twitter groups.
  #
  # extra_tags are rendered between the OG and Twitter groups, which is where
  # article:* metadata belongs on a post page.
  def seo_head_tags(title:, description:, url:, type: "website", image: nil, extra_tags: nil, json_ld: nil)
    image_url = image || default_og_image_url

    tags = [ meta_description_tag(description) ]
    tags << open_graph_tags(title: title, description: description, url: url, type: type, image: image_url)
    tags.concat(Array(extra_tags))
    tags << twitter_card_tags(title: title, description: description, image: image_url)
    tags << canonical_tag(url)
    tags << json_ld_tag(json_ld) if json_ld.present?

    safe_join(tags.compact, "\n")
  end

  def meta_description_tag(text)
    return if text.blank?

    tag.meta(name: "description", content: text.truncate(160))
  end

  def open_graph_tags(title:, description:, url:, type: "website", image: nil)
    image_url = image || default_og_image_url
    tags = []
    tags << tag.meta(property: "og:title", content: title)
    tags << tag.meta(property: "og:type", content: type)
    tags << tag.meta(property: "og:url", content: url)
    tags << tag.meta(property: "og:site_name", content: site_name)
    tags << tag.meta(property: "og:description", content: description) if description.present?
    tags << tag.meta(property: "og:image", content: image_url) if image_url.present?
    safe_join(tags, "\n")
  end

  def twitter_card_tags(title:, description:, image: nil)
    image_url = image || default_og_image_url
    card_type = image_url.present? ? "summary_large_image" : "summary"
    tags = []
    tags << tag.meta(name: "twitter:card", content: card_type)
    tags << tag.meta(name: "twitter:title", content: title)
    tags << tag.meta(name: "twitter:description", content: description) if description.present?
    tags << tag.meta(name: "twitter:image", content: image_url) if image_url.present?
    safe_join(tags, "\n")
  end

  def canonical_tag(url)
    tag.link(rel: "canonical", href: url)
  end

  def meta_tags_for_post(post)
    seo_head_tags(
      title: post.title,
      description: post.seo_description,
      url: post_url(post, slug: post.slug),
      type: "article",
      image: post_og_image_url(post),
      extra_tags: article_meta_tags(post)
    )
  end

  private

  def article_meta_tags(post)
    identity = post.user.identity
    author = identity.handle.present? ? author_url(identity, handle: identity.handle) : post.user.display_name

    tags = [
      tag.meta(property: "article:published_time", content: post.published_at&.iso8601),
      tag.meta(property: "article:author", content: author)
    ]
    post.tags.each { |t| tags << tag.meta(property: "article:tag", content: t.name) }
    tags
  end
end
