require "test_helper"

class Admin::CommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(:admin)
  end

  test "GET index lists comments" do
    get admin_comments_path
    assert_response :success
  end

  test "GET index filters by pending" do
    get admin_comments_path(filter: "pending")
    assert_response :success
  end

  test "PATCH update approves comment" do
    comment = comments(:pending_comment)
    patch admin_comment_path(comment), params: { approved: true }
    assert_redirected_to admin_comments_path
    assert comment.reload.approved?
  end

  test "PATCH update rejects comment" do
    comment = comments(:top_level)
    patch admin_comment_path(comment), params: { approved: false }
    assert_redirected_to admin_comments_path
    assert_not comment.reload.approved?
  end

  test "DELETE destroy removes comment" do
    assert_difference "Comment.count", -1 do
      delete admin_comment_path(comments(:pending_comment))
    end
    assert_redirected_to admin_comments_path
  end
end
