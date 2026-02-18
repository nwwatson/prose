xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0",
  "xmlns:atom" => "http://www.w3.org/2005/Atom",
  "xmlns:content" => "http://purl.org/rss/1.0/modules/content/",
  "xmlns:dc" => "http://purl.org/dc/elements/1.1/" do
  xml.channel do
    xml.title site_name
    xml.description site_description
    xml.link root_url
    xml.tag! "atom:link", href: feed_url(format: :xml), rel: "self", type: "application/rss+xml"
    xml.language "en"

    @posts.each do |post|
      xml.item do
        xml.title post.title
        xml.description post.seo_description if post.seo_description.present?
        xml.tag! "content:encoded", post.content.to_s
        xml.pubDate post.published_at.rfc822
        xml.link post_url(post, slug: post.slug)
        xml.guid post_url(post, slug: post.slug)
        xml.tag! "dc:creator", post.user.display_name
        xml.category post.category.name if post.category.present?
        post.tags.each do |tag|
          xml.category tag.name
        end
      end
    end
  end
end
