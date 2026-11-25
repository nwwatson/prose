require "test_helper"

class Admin::XPostsControllerTest < ActionDispatch::IntegrationTest
  OEMBED = { "html" => "<blockquote><p>hello</p></blockquote>", "author_name" => "Jane", "author_url" => "https://x.com/jane" }.freeze

  test "requires authentication" do
    post "/admin/x_posts", params: { url: "https://x.com/jane/status/1" }
    assert_redirected_to "/admin/session/new"
  end

  test "create returns the attachment sgid and rendered embed" do
    sign_in_as(:writer)

    stub_oembed_fetch(OEMBED) do
      assert_difference "XPost.count", 1 do
        post "/admin/x_posts", params: { url: "https://twitter.com/jane/status/1?s=20" }
      end
    end

    assert_response :success
    x_post = XPost.find_by!(url: "https://x.com/jane/status/1")
    json = response.parsed_body
    assert_equal x_post.attachable_sgid, json["sgid"]
    assert_includes json["html"], "x-post-embed"
    assert_includes json["html"], "hello"
  end

  test "create renders the embed for the editor's JSON request" do
    sign_in_as(:writer)

    stub_oembed_fetch(OEMBED) do
      post "/admin/x_posts", params: { url: "https://x.com/jane/status/3" }, headers: { "Accept" => "application/json" }, as: :json
    end

    assert_response :success
    assert_includes response.parsed_body["html"], "x-post-embed"
  end

  test "create rejects a missing url" do
    sign_in_as(:admin)

    assert_no_difference "XPost.count" do
      post "/admin/x_posts", as: :json
    end

    assert_response :unprocessable_entity
    assert_equal "Could not process X post URL", response.parsed_body["error"]
  end

  test "create reuses an existing post for the same url" do
    sign_in_as(:admin)
    stub_oembed_fetch(OEMBED) { XPost.find_or_create_from_url("https://x.com/jane/status/2") }

    with_singleton_stub(OembedFetcher, :fetch, ->(*) { flunk "should not refetch" }) do
      assert_no_difference "XPost.count" do
        post "/admin/x_posts", params: { url: "https://x.com/jane/status/2" }
      end
    end

    assert_response :success
  end

  test "create rejects a blank url" do
    sign_in_as(:admin)

    assert_no_difference "XPost.count" do
      post "/admin/x_posts", params: { url: "" }, as: :json
    end

    assert_response :unprocessable_entity
    assert_equal "Could not process X post URL", response.parsed_body["error"]
  end

  test "create reports validation errors" do
    sign_in_as(:admin)
    invalid = XPost.new
    invalid.validate

    with_singleton_stub(XPost, :find_or_create_from_url, ->(*) { invalid }) do
      post "/admin/x_posts", params: { url: "https://x.com/jane/status/9" }, as: :json
    end

    assert_response :unprocessable_entity
    assert_equal invalid.errors.full_messages.join(", "), response.parsed_body["error"]
  end
end
