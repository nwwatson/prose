xml.instruct! :xml, version: "1.0"
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
  xml.url do
    xml.loc root_url
    xml.changefreq "daily"
    xml.priority 1.0
  end

  @pages.each do |pg|
    xml.url do
      xml.loc page_url(pg.slug)
      xml.lastmod pg.updated_at.iso8601
      xml.changefreq "monthly"
      xml.priority 0.5
    end
  end

  @posts.each do |post|
    xml.url do
      xml.loc post_url(post, slug: post.slug)
      xml.lastmod post.updated_at.iso8601
      xml.changefreq "weekly"
      xml.priority 0.8
    end
  end

  @categories.each do |category|
    xml.url do
      xml.loc category_url(category, slug: category.slug)
      xml.changefreq "weekly"
      xml.priority 0.6
    end
  end

  @tags.each do |tag|
    xml.url do
      xml.loc tag_url(tag, slug: tag.slug)
      xml.changefreq "weekly"
      xml.priority 0.5
    end
  end
end
