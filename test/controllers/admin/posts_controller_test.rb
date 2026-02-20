require "test_helper"

class Admin::PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(:admin)
  end

  test "GET index lists posts" do
    get admin_posts_path
    assert_response :success
    assert_select "table"
  end

  test "GET index filters by status" do
    get admin_posts_path(status: "published")
    assert_response :success
  end

  test "GET index filters by draft status" do
    get admin_posts_path(status: "draft")
    assert_response :success
  end

  test "GET new renders form" do
    get new_admin_post_path
    assert_response :success
    assert_select "form"
  end

  test "POST create creates a draft post" do
    assert_difference "Post.count", 1 do
      post admin_posts_path, params: { post: { title: "New Test Post" } }
    end
    assert_redirected_to edit_admin_post_path(Post.last)
    assert Post.last.draft?
  end

  test "POST create with invalid data re-renders form" do
    post admin_posts_path, params: { post: { title: "" } }
    assert_response :unprocessable_entity
  end

  test "GET edit renders form" do
    get edit_admin_post_path(posts(:draft_post))
    assert_response :success
  end

  test "PATCH update updates post" do
    patch admin_post_path(posts(:draft_post)), params: { post: { title: "Updated Title" } }
    assert_redirected_to edit_admin_post_path(posts(:draft_post))
    assert_equal "Updated Title", posts(:draft_post).reload.title
  end

  test "DELETE destroy removes post" do
    assert_difference "Post.count", -1 do
      delete admin_post_path(posts(:draft_post))
    end
    assert_redirected_to admin_posts_path
  end

  test "POST create as JSON returns created with post data" do
    assert_difference "Post.count", 1 do
      post admin_posts_path, params: { post: { title: "Autosaved Post" } }, as: :json
    end
    assert_response :created
    json = JSON.parse(response.body)
    assert json["slug"].present?
    assert json["url"].present?
    assert json["edit_url"].present?
  end

  test "POST create as JSON with blank title returns errors" do
    post admin_posts_path, params: { post: { title: "" } }, as: :json
    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json["errors"].any?
  end

  test "PATCH update as JSON returns ok with post data" do
    patch admin_post_path(posts(:draft_post)), params: { post: { title: "Updated via JSON" } }, as: :json
    assert_response :ok
    json = JSON.parse(response.body)
    assert json["slug"].present?
    assert json["url"].present?
    assert json["edit_url"].present?
    assert_equal "Updated via JSON", posts(:draft_post).reload.title
  end

  test "PATCH update as JSON with blank title returns errors" do
    patch admin_post_path(posts(:draft_post)), params: { post: { title: "" } }, as: :json
    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json["errors"].any?
  end

  test "requires authentication" do
    delete admin_session_path
    get admin_posts_path
    assert_redirected_to new_admin_session_path
  end
end
