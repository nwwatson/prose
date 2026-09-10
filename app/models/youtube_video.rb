class YouTubeVideo < ApplicationRecord
  include OembedAttachable

  validates :url, presence: true, uniqueness: true
  validates :video_id, presence: true

  def self.normalize_url(url)
    url = url.strip
    uri = URI.parse(url)
    vid = extract_video_id_from_uri(uri)
    vid ? "https://www.youtube.com/watch?v=#{vid}" : url
  rescue URI::InvalidURIError
    url
  end

  def self.valid_oembed_url?(url)
    extract_video_id(url).present?
  end

  def self.extract_video_id(url)
    uri = URI.parse(url)
    extract_video_id_from_uri(uri)
  rescue URI::InvalidURIError
    nil
  end

  def self.extract_video_id_from_uri(uri)
    host = uri.host&.downcase&.gsub(/\Awww\./, "")

    case host
    when "youtube.com", "m.youtube.com"
      if uri.path == "/watch"
        params = URI.decode_www_form(uri.query || "").to_h
        params["v"]
      elsif uri.path.start_with?("/embed/")
        uri.path.split("/")[2]
      end
    when "youtu.be"
      uri.path[1..]
    end
  end

  private_class_method :extract_video_id_from_uri

  def oembed_endpoint
    "https://www.youtube.com/oembed?url=#{CGI.escape(url)}&format=json"
  end

  def apply_oembed(data)
    self.title = data["title"]
    self.author_name = data["author_name"]
    self.thumbnail_url = data["thumbnail_url"]
  end

  private

  def assign_oembed_url_attributes
    self.video_id = self.class.extract_video_id(url)
  end
end
