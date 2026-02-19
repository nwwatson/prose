class XPost < ApplicationRecord
  include ActionText::Attachable

  validates :url, presence: true, uniqueness: true

  def to_attachable_partial_path
    "x_posts/x_post"
  end

  def to_trix_content_attachment_partial_path
    "x_posts/x_post"
  end

  def self.find_or_create_from_url(url)
    normalized = normalize_url(url)
    find_or_create_by(url: normalized) do |x_post|
      x_post.fetch_oembed!
    end
  end

  def fetch_oembed!
    uri = URI("https://publish.twitter.com/oembed?url=#{CGI.escape(url)}&omit_script=true")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.cert_store = OpenSSL::X509::Store.new.tap { |s| s.set_default_paths; s.flags = 0 }
    response = http.get(uri.request_uri)
    data = JSON.parse(response.body)
    self.embed_html = data["html"]
    self.author_name = data["author_name"]
    self.author_username = data["author_url"]&.split("/")&.last
  rescue StandardError => e
    Rails.logger.warn("XPost oEmbed fetch failed for #{url}: #{e.message}")
    self.embed_html = nil
  end

  def self.normalize_url(url)
    url.gsub("twitter.com", "x.com").split("?").first
  end
end
