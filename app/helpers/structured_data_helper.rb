module StructuredDataHelper
  def json_ld_tag(data)
    tag.script(data.to_json.html_safe, type: "application/ld+json")
  end

  def json_ld_for_post(post)
    data = {
      "@context": "https://schema.org",
      "@type": "Article",
      headline: post.title,
      datePublished: post.published_at&.iso8601,
      dateModified: post.updated_at.iso8601,
      author: author_json_ld(post.user.identity)
    }
    description = post.seo_description
    data[:description] = description if description.present?

    image = post_og_image_url(post)
    data[:image] = image if image.present?

    data[:wordCount] = post.reading_time_minutes * 238

    if post.tags.any?
      data[:keywords] = post.tags.map(&:name).join(", ")
    end

    json_ld_tag(data)
  end

  def json_ld_for_author(identity)
    data = {
      "@context": "https://schema.org",
      "@type": "Person",
      name: identity.name,
      url: author_url(identity, handle: identity.handle)
    }
    data[:description] = strip_tags(identity.bio_html).truncate(160) if identity.bio.present?
    data[:sameAs] = [ identity.website_url, identity.twitter_url, identity.github_url ].compact if identity.has_social_links?

    json_ld_tag(data)
  end

  def json_ld_breadcrumb_list(post)
    items = breadcrumb_items(post).each_with_index.map do |crumb, index|
      item = { "@type": "ListItem", position: index + 1, name: crumb[:name] }
      item[:item] = crumb[:url] if crumb[:url]
      item
    end

    json_ld_tag({
      "@context": "https://schema.org",
      "@type": "BreadcrumbList",
      itemListElement: items
    })
  end

  private

  def author_json_ld(identity)
    data = { "@type": "Person", name: identity.name }
    data[:url] = author_url(identity, handle: identity.handle) if identity.handle.present?
    data
  end
end
