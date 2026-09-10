require "test_helper"

class YouTubeVideoTest < ActiveSupport::TestCase
  test "normalize_url canonicalizes watch, embed, and short urls" do
    assert_equal "https://www.youtube.com/watch?v=abc123", YouTubeVideo.normalize_url("https://www.youtube.com/watch?v=abc123&t=10s")
    assert_equal "https://www.youtube.com/watch?v=abc123", YouTubeVideo.normalize_url("https://youtu.be/abc123")
    assert_equal "https://www.youtube.com/watch?v=abc123", YouTubeVideo.normalize_url("https://www.youtube.com/embed/abc123")
  end

  test "normalize_url returns the original string for an unparseable url" do
    assert_equal "not a url", YouTubeVideo.normalize_url("not a url")
  end

  test "find_or_create_from_url extracts the video id and applies oembed data" do
    data = { "title" => "Cool Video", "author_name" => "Jane", "thumbnail_url" => "https://img.example.com/abc123.jpg" }

    video = stub_oembed_fetch(data) do
      YouTubeVideo.find_or_create_from_url("https://youtu.be/abc123")
    end

    assert video.persisted?
    assert_equal "abc123", video.video_id
    assert_equal "https://www.youtube.com/watch?v=abc123", video.url
    assert_equal "Cool Video", video.title
    assert_equal "Jane", video.author_name
    assert_equal data["thumbnail_url"], video.thumbnail_url
  end

  test "find_or_create_from_url returns nil for a url with no video id" do
    assert_nil YouTubeVideo.find_or_create_from_url("https://www.youtube.com/feed/trending")
  end

  test "find_or_create_from_url returns the existing record for a duplicate url" do
    existing = YouTubeVideo.create!(url: "https://www.youtube.com/watch?v=abc123", video_id: "abc123")

    found = YouTubeVideo.find_or_create_from_url("https://youtu.be/abc123")

    assert_equal existing, found
    assert_equal 1, YouTubeVideo.count
  end

  test "oembed_endpoint builds the youtube.com oembed url" do
    video = YouTubeVideo.new(url: "https://www.youtube.com/watch?v=abc123", video_id: "abc123")

    assert_equal "https://www.youtube.com/oembed?url=https%3A%2F%2Fwww.youtube.com%2Fwatch%3Fv%3Dabc123&format=json", video.oembed_endpoint
  end

  test "attachable partial paths" do
    video = YouTubeVideo.new

    assert_equal "youtube_videos/youtube_video", video.to_attachable_partial_path
    assert_equal "youtube_videos/youtube_video", video.to_trix_content_attachment_partial_path
  end

  private

  def stub_oembed_fetch(data)
    original_fetch = OembedFetcher.method(:fetch)
    OembedFetcher.define_singleton_method(:fetch) { |*| data }
    yield
  ensure
    OembedFetcher.define_singleton_method(:fetch, original_fetch)
  end
end
