module MetaTagsHelper
  def page_title(title = nil)
    if title.present?
      "#{title} — #{site_name}"
    else
      site_name
    end
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

  def json_ld_tag(data)
    tag.script(data.to_json.html_safe, type: "application/ld+json")
  end

  def meta_tags_for_post(post)
    description = post.seo_description
    url = post_url(post, slug: post.slug)
    image = post.featured_image.attached? ? optimized_og_image_url(post) : nil

    tags = []
    tags << meta_description_tag(description)
    tags << open_graph_tags(
      title: post.title,
      description: description,
      url: url,
      type: "article",
      image: image
    )
    tags << tag.meta(property: "article:published_time", content: post.published_at&.iso8601)
    tags << tag.meta(property: "article:author", content: post.user.display_name)
    post.tags.each do |t|
      tags << tag.meta(property: "article:tag", content: t.name)
    end
    tags << twitter_card_tags(title: post.title, description: description, image: image)
    tags << canonical_tag(url)

    safe_join(tags.compact, "\n")
  end

  def json_ld_for_post(post)
    data = {
      "@context": "https://schema.org",
      "@type": "Article",
      headline: post.title,
      datePublished: post.published_at&.iso8601,
      dateModified: post.updated_at.iso8601,
      author: {
        "@type": "Person",
        name: post.user.display_name
      }
    }
    description = post.seo_description
    data[:description] = description if description.present?

    if post.featured_image.attached?
      data[:image] = optimized_og_image_url(post)
    end

    data[:wordCount] = post.reading_time_minutes * 238

    if post.tags.any?
      data[:keywords] = post.tags.map(&:name).join(", ")
    end

    json_ld_tag(data)
  end
end
