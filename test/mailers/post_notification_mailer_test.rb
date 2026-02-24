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

  test "new_post email uses branding colors" do
    site = SiteSetting.current
    site.update!(email_accent_color: "#ee1122", email_heading_color: "#aabbcc")
    subscriber = subscribers(:confirmed)
    post = posts(:published_post)
    mail = PostNotificationMailer.new_post(subscriber, post)

    assert_includes mail.body.encoded, "#ee1122"
    assert_includes mail.body.encoded, "#aabbcc"
  end

  test "new_post email includes unsubscribe link" do
    subscriber = subscribers(:confirmed)
    post = posts(:published_post)
    mail = PostNotificationMailer.new_post(subscriber, post)

    assert_includes mail.body.encoded, "unsubscribe"
    assert mail["List-Unsubscribe"].present?, "List-Unsubscribe header should be set"
    assert_includes mail["List-Unsubscribe"].value, "unsubscribe"
  end

  test "new_post email uses custom background and font" do
    site = SiteSetting.current
    site.update!(email_background_color: "#fafafa", email_font_family: "georgia")
    subscriber = subscribers(:confirmed)
    post = posts(:published_post)
    mail = PostNotificationMailer.new_post(subscriber, post)

    assert_includes mail.body.encoded, "#fafafa"
    assert_includes mail.body.encoded, "Georgia"
  end

  test "new_post email includes footer text when set" do
    site = SiteSetting.current
    site.update!(email_footer_text: "Thanks for reading our blog!")
    subscriber = subscribers(:confirmed)
    post = posts(:published_post)
    mail = PostNotificationMailer.new_post(subscriber, post)

    assert_includes mail.body.encoded, "Thanks for reading our blog!"
  end
end
