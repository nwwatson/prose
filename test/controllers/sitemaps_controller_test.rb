require "test_helper"

class SitemapsControllerTest < ActionDispatch::IntegrationTest
  test "GET index renders sitemap XML" do
    get sitemap_path(format: :xml)
    assert_response :success
    assert_equal "application/xml; charset=utf-8", response.content_type
    assert_includes response.body, post_url(posts(:published_post), slug: posts(:published_post).slug)
  end

  test "sitemap does not include draft posts" do
    get sitemap_path(format: :xml)
    assert_not_includes response.body, posts(:draft_post).slug
  end
end
