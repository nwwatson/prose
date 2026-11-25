require "test_helper"

# Links already sitting in inboxes were signed with these verifier names and a
# 30-day expiry. The names are written out here so a rename can't slip through.
class EmailLinkTokensTest < ActiveSupport::TestCase
  setup do
    @subscriber = subscribers(:confirmed)
    @comment = comments(:top_level)
  end

  test "unsubscribe links that were already emailed still resolve" do
    token = Rails.application.message_verifier("unsubscribe").generate(@subscriber.id, expires_in: 30.days)

    assert_equal @subscriber, Subscriber.find_by_unsubscribe_token(token)
  end

  test "comment notification links that were already emailed still resolve" do
    token = Rails.application.message_verifier("comment_notification").generate(@comment.id, expires_in: 30.days)

    assert_equal @comment, Comment.find_by_notification_token(token)
  end

  test "new tokens keep the same verifier name" do
    assert_equal @subscriber.id, Rails.application.message_verifier("unsubscribe").verified(@subscriber.unsubscribe_token)
    assert_equal @comment.id, Rails.application.message_verifier("comment_notification").verified(@comment.notification_token)
  end

  test "new tokens last 30 days" do
    unsubscribe = @subscriber.unsubscribe_token
    notification = @comment.notification_token

    travel 30.days - 1.minute do
      assert_equal @subscriber, Subscriber.find_by_unsubscribe_token(unsubscribe)
      assert_equal @comment, Comment.find_by_notification_token(notification)
    end

    travel 30.days + 1.minute do
      assert_nil Subscriber.find_by_unsubscribe_token(unsubscribe)
      assert_nil Comment.find_by_notification_token(notification)
    end
  end

  test "garbage and tokens made for another purpose are rejected" do
    assert_nil Subscriber.find_by_unsubscribe_token("garbage")
    assert_nil Subscriber.find_by_unsubscribe_token(@subscriber.email_preferences_token)
    assert_nil Comment.find_by_notification_token(nil)
    assert_nil Comment.find_by_notification_token(@subscriber.unsubscribe_token)
  end
end
