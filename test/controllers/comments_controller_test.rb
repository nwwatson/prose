require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  test "POST create requires identity" do
    post post_comments_path(posts(:published_post)), params: { comment: { body: "Test" } }
    assert_redirected_to root_path
  end

  test "POST create creates comment as subscriber" do
    sign_in_subscriber(subscribers(:confirmed))

    assert_difference "Comment.count", 1 do
      post post_comments_path(posts(:published_post)), params: { comment: { body: "Great article!" } }
    end
  end

  test "POST create creates comment as staff user" do
    sign_in_as(:admin)

    assert_difference "Comment.count", 1 do
      post post_comments_path(posts(:published_post)), params: { comment: { body: "Staff comment!" } }
    end
  end
end
