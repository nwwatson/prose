require "test_helper"

class FeedsControllerTest < ActionDispatch::IntegrationTest
  test "GET index renders RSS feed" do
    get feed_path(format: :xml)
    assert_response :success
    assert_equal "application/xml; charset=utf-8", response.content_type
    assert_includes response.body, posts(:published_post).title
  end

  test "RSS feed does not include draft posts" do
    get feed_path(format: :xml)
    assert_not_includes response.body, posts(:draft_post).title
  end
end
