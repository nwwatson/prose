class YouTubeVideo < ApplicationRecord
  include ActionText::Attachable

  validates :url, presence: true, uniqueness: true
  validates :video_id, presence: true

  def to_attachable_partial_path
    "youtube_videos/youtube_video"
  end

  def to_trix_content_attachment_partial_path
    "youtube_videos/youtube_video"
  end

  def self.find_or_create_from_url(url)
    normalized = normalize_url(url)
    vid = extract_video_id(normalized)
    return nil unless vid

    find_or_create_by(url: normalized) do |video|
      video.video_id = vid
      video.fetch_oembed!
    end
  end

  def fetch_oembed!
    uri = URI("https://www.youtube.com/oembed?url=#{CGI.escape(url)}&format=json")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.cert_store = OpenSSL::X509::Store.new.tap { |s| s.set_default_paths; s.flags = 0 }
    response = http.get(uri.request_uri)
    data = JSON.parse(response.body)
    self.title = data["title"]
    self.author_name = data["author_name"]
    self.thumbnail_url = data["thumbnail_url"]
  rescue StandardError => e
    Rails.logger.warn("YouTubeVideo oEmbed fetch failed for #{url}: #{e.message}")
  end

  def self.normalize_url(url)
    url = url.strip
    uri = URI.parse(url)
    vid = extract_video_id_from_uri(uri)
    vid ? "https://www.youtube.com/watch?v=#{vid}" : url
  rescue URI::InvalidURIError
    url
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
end
