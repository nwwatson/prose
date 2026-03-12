require "test_helper"

class CommentMailerTest < ActionMailer::TestCase
  test "reply_notification sends to parent comment author" do
    reply = comments(:reply)
    reply.parent_comment.update!(notify_on_reply: true)

    email = CommentMailer.reply_notification(reply)
    assert_equal [ subscribers(:confirmed).email ], email.to
    assert_includes email.subject, SiteSetting.current.site_name
  end

  test "reply_notification includes post title in body" do
    reply = comments(:reply)
    reply.parent_comment.update!(notify_on_reply: true)

    email = CommentMailer.reply_notification(reply)
    assert_includes email.html_part.body.to_s, posts(:published_post).title
  end

  test "reply_notification includes unsubscribe link" do
    reply = comments(:reply)
    reply.parent_comment.update!(notify_on_reply: true)

    email = CommentMailer.reply_notification(reply)
    assert_includes email.html_part.body.to_s, "comment_notification"
  end
end
