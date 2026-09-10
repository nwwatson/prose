class XPost < ApplicationRecord
  include OembedAttachable

  validates :url, presence: true, uniqueness: true

  def self.normalize_url(url)
    url.gsub("twitter.com", "x.com").split("?").first
  end

  def oembed_endpoint
    "https://publish.twitter.com/oembed?url=#{CGI.escape(url)}&omit_script=true"
  end

  def apply_oembed(data)
    self.embed_html = data["html"]
    self.author_name = data["author_name"]
    self.author_username = data["author_url"]&.split("/")&.last
  end
end
