require "test_helper"

class CommentNotificationsControllerTest < ActionDispatch::IntegrationTest
  test "DELETE with valid token disables notify_on_reply" do
    comment = comments(:top_level)
    comment.update!(notify_on_reply: true)

    token = Rails.application.message_verifier("comment_notification").generate(comment.id, expires_in: 30.days)
    delete comment_notification_path(token: token)

    comment.reload
    assert_not comment.notify_on_reply?
    assert_redirected_to post_path(comment.post, slug: comment.post.slug)
  end

  test "DELETE with invalid token redirects to root" do
    delete comment_notification_path(token: "invalid")
    assert_redirected_to root_path
  end
end
