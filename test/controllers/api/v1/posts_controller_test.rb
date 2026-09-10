require "test_helper"

class Api::V1::PostsControllerTest < ActionDispatch::IntegrationTest
  VALID_TOKEN = "prose_admin_test_token_1234567890abcdef"

  def auth_header
    { "Authorization" => "Bearer #{VALID_TOKEN}" }
  end

  # --- Auth ---

  test "rejects requests without a token" do
    get "/api/v1/posts"
    assert_response :unauthorized
  end

  test "rejects requests with a revoked token" do
    get "/api/v1/posts", headers: { "Authorization" => "Bearer prose_revoked_test_token_1234567890abcdef" }
    assert_response :unauthorized
  end

  # --- Index ---

  test "lists posts" do
    get "/api/v1/posts", headers: auth_header
    assert_response :success

    body = JSON.parse(response.body)
    assert body["posts"].is_a?(Array)
    assert_equal Post.count.to_s, response.headers["X-Total-Count"]
  end

  test "filters posts by status" do
    get "/api/v1/posts", params: { status: "draft" }, headers: auth_header
    assert_response :success

    body = JSON.parse(response.body)
    assert body["posts"].all? { |p| p["status"] == "draft" }
  end

  test "filters posts by category" do
    get "/api/v1/posts", params: { category: "Technology" }, headers: auth_header
    assert_response :success

    body = JSON.parse(response.body)
    assert body["posts"].all? { |p| p["category"] == "Technology" }
  end

  test "paginates and sets Link header on further pages" do
    get "/api/v1/posts", params: { per_page: 1 }, headers: auth_header
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal 1, body["posts"].length
    assert_includes response.headers["Link"], 'rel="next"'
  end

  # --- Show ---

  test "shows a post by slug" do
    get "/api/v1/posts/#{posts(:published_post).slug}", headers: auth_header
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal "Published Post", body["title"]
    assert body.key?("content_html")
  end

  test "shows a post by numeric id" do
    get "/api/v1/posts/#{posts(:published_post).id}", headers: auth_header
    assert_response :success
  end

  test "returns 404 for a missing post" do
    get "/api/v1/posts/does-not-exist", headers: auth_header
    assert_response :not_found
  end

  # --- Create ---

  test "creates a draft post from markdown" do
    assert_difference "Post.count", 1 do
      post "/api/v1/posts",
        params: { title: "New Post", content: "# Hello", category: "Technology", tags: %w[Ruby Rails] },
        headers: auth_header
    end

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "New Post", body["title"]
    assert_equal "draft", body["status"]
    assert_equal "Technology", body["category"]
    assert_includes body["content_html"], "<h1>"
  end

  test "rejects an invalid post" do
    assert_no_difference "Post.count" do
      post "/api/v1/posts", params: { title: "" }, headers: auth_header
    end

    assert_response :unprocessable_entity
    assert JSON.parse(response.body)["error"].present?
  end

  # --- Update ---

  test "updates only provided fields" do
    post_record = posts(:draft_post)

    patch "/api/v1/posts/#{post_record.slug}", params: { subtitle: "Updated subtitle" }, headers: auth_header
    assert_response :success

    post_record.reload
    assert_equal "Updated subtitle", post_record.subtitle
    assert_equal "Draft Post", post_record.title
  end

  # --- Destroy ---

  test "deletes a post" do
    post_record = posts(:draft_post)

    assert_difference "Post.count", -1 do
      delete "/api/v1/posts/#{post_record.slug}", headers: auth_header
    end

    assert_response :no_content
  end

  # --- Publish / Schedule / Unpublish ---

  test "publishes a draft post" do
    post_record = posts(:draft_post)

    post "/api/v1/posts/#{post_record.slug}/publish", headers: auth_header
    assert_response :success

    post_record.reload
    assert post_record.published?
  end

  test "schedules a draft post" do
    post_record = posts(:draft_post)
    time = 2.days.from_now.iso8601

    post "/api/v1/posts/#{post_record.slug}/schedule", params: { published_at: time }, headers: auth_header
    assert_response :success

    post_record.reload
    assert post_record.scheduled?
  end

  test "rejects an invalid schedule datetime" do
    post_record = posts(:draft_post)

    post "/api/v1/posts/#{post_record.slug}/schedule", params: { published_at: "not-a-date" }, headers: auth_header
    assert_response :unprocessable_entity
  end

  test "unpublishes a published post" do
    post_record = posts(:published_post)

    post "/api/v1/posts/#{post_record.slug}/unpublish", headers: auth_header
    assert_response :success

    post_record.reload
    assert post_record.draft?
  end
end
