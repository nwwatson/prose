require "test_helper"

class Admin::YouTubeVideosControllerTest < ActionDispatch::IntegrationTest
  OEMBED = { "title" => "Cool Video", "author_name" => "Jane", "thumbnail_url" => "https://img.example.com/abc123.jpg" }.freeze

  test "requires authentication" do
    post "/admin/youtube_videos", params: { url: "https://youtu.be/abc123" }
    assert_redirected_to "/admin/session/new"
  end

  test "create returns the attachment sgid and rendered embed" do
    sign_in_as(:writer)

    stub_oembed_fetch(OEMBED) do
      assert_difference "YouTubeVideo.count", 1 do
        post "/admin/youtube_videos", params: { url: "https://youtu.be/abc123" }
      end
    end

    assert_response :success
    video = YouTubeVideo.find_by!(url: "https://www.youtube.com/watch?v=abc123")
    json = response.parsed_body
    assert_equal video.attachable_sgid, json["sgid"]
    assert_includes json["html"], "https://www.youtube.com/embed/abc123"
    assert_includes json["html"], "Cool Video"
  end

  test "create renders the embed for the editor's JSON request" do
    sign_in_as(:writer)

    stub_oembed_fetch(OEMBED) do
      post "/admin/youtube_videos", params: { url: "https://youtu.be/xyz789" }, headers: { "Accept" => "application/json" }, as: :json
    end

    assert_response :success
    assert_includes response.parsed_body["html"], "https://www.youtube.com/embed/xyz789"
  end

  test "create rejects a missing url" do
    sign_in_as(:admin)

    assert_no_difference "YouTubeVideo.count" do
      post "/admin/youtube_videos", as: :json
    end

    assert_response :unprocessable_entity
    assert_equal "Could not process YouTube URL", response.parsed_body["error"]
  end

  test "create rejects a url with no video id without fetching" do
    sign_in_as(:admin)

    with_singleton_stub(OembedFetcher, :fetch, ->(*) { flunk "should not fetch" }) do
      assert_no_difference "YouTubeVideo.count" do
        post "/admin/youtube_videos", params: { url: "https://www.youtube.com/feed/trending" }, as: :json
      end
    end

    assert_response :unprocessable_entity
    assert_equal "Could not process YouTube URL", response.parsed_body["error"]
  end

  test "create reports validation errors like the X embed does" do
    sign_in_as(:admin)
    invalid = YouTubeVideo.new
    invalid.validate

    with_singleton_stub(YouTubeVideo, :find_or_create_from_url, ->(*) { invalid }) do
      post "/admin/youtube_videos", params: { url: "https://youtu.be/abc123" }, as: :json
    end

    assert_response :unprocessable_entity
    assert_equal invalid.errors.full_messages.join(", "), response.parsed_body["error"]
  end
end
