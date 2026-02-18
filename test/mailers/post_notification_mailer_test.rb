require "test_helper"

class PostNotificationMailerTest < ActionMailer::TestCase
  test "new_post email" do
    subscriber = subscribers(:confirmed)
    post = posts(:published_post)
    mail = PostNotificationMailer.new_post(subscriber, post)

    assert_equal "New post: #{post.title}", mail.subject
    assert_equal [ subscriber.email ], mail.to
    assert_includes mail.body.encoded, post.title
  end
end
