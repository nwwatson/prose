require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  test "GET index renders home page" do
    get root_path
    assert_response :success
    assert_select "h2", text: posts(:featured_post).title
  end

  test "GET index shows non-featured posts" do
    get root_path
    assert_response :success
    assert_select "h3", text: posts(:published_post).title
  end

  test "GET index does not show draft posts" do
    get root_path
    assert_response :success
    assert_select "h3", text: posts(:draft_post).title, count: 0
  end

  test "GET show renders published post" do
    get post_path(posts(:published_post), slug: posts(:published_post).slug)
    assert_response :success
    assert_select "h1", text: posts(:published_post).title
  end

  test "GET show returns 404 for draft post" do
    get post_path(posts(:draft_post), slug: posts(:draft_post).slug)
    assert_response :not_found
  end

  test "GET show includes meta tags" do
    get post_path(posts(:published_post), slug: posts(:published_post).slug)
    assert_response :success
    assert_select "meta[property='og:title']" do |elements|
      assert_equal posts(:published_post).title, elements.first["content"]
    end
  end

  test "GET show includes JSON-LD" do
    get post_path(posts(:published_post), slug: posts(:published_post).slug)
    assert_select "script[type='application/ld+json']"
  end

  test "GET index with search query filters results" do
    get root_path(q: "Published")
    assert_response :success
    assert_select "h3", text: posts(:published_post).title
  end

  test "GET index with search shows body snippet" do
    get root_path(q: "innovation")
    assert_response :success
    assert_select "mark"
  end

  test "GET index with non-matching search shows no posts" do
    get root_path(q: "xyznonexistent")
    assert_response :success
  end
end
