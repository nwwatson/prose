require "test_helper"

class CommentReplyNotificationJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  test "sends notification email for reply to comment with notify_on_reply" do
    reply = comments(:reply)
    reply.parent_comment.update!(notify_on_reply: true)

    assert_enqueued_emails 1 do
      CommentReplyNotificationJob.perform_now(reply)
    end
  end

  test "does not send when parent notify_on_reply is false" do
    reply = comments(:reply)
    reply.parent_comment.update!(notify_on_reply: false)

    assert_no_enqueued_emails do
      CommentReplyNotificationJob.perform_now(reply)
    end
  end

  test "does not send when parent is deleted" do
    reply = comments(:reply)
    reply.parent_comment.update!(notify_on_reply: true, deleted_at: Time.current)

    assert_no_enqueued_emails do
      CommentReplyNotificationJob.perform_now(reply)
    end
  end

  test "does not send when replier is same as parent author" do
    parent = comments(:top_level)
    parent.update!(notify_on_reply: true)
    reply = Comment.new(
      post: posts(:published_post),
      identity: parent.identity,
      parent_comment: parent,
      body: "Self reply"
    )
    reply.save!(validate: false)

    assert_no_enqueued_emails do
      CommentReplyNotificationJob.perform_now(reply)
    end
  end
end
