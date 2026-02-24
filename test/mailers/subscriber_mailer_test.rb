require "test_helper"

class SubscriberMailerTest < ActionMailer::TestCase
  test "confirmation email" do
    subscriber = subscribers(:unconfirmed)
    subscriber.generate_auth_token!
    mail = SubscriberMailer.confirmation(subscriber)

    assert_equal "Confirm your subscription to #{SiteSetting.current.site_name}", mail.subject
    assert_equal [ subscriber.email ], mail.to
    assert_includes mail.body.encoded, subscriber.auth_token
  end

  test "confirmation email uses branding colors" do
    site = SiteSetting.current
    site.update!(email_accent_color: "#ff5500", email_heading_color: "#112233")
    subscriber = subscribers(:unconfirmed)
    subscriber.generate_auth_token!
    mail = SubscriberMailer.confirmation(subscriber)

    assert_includes mail.body.encoded, "#ff5500"
    assert_includes mail.body.encoded, "#112233"
  end

  test "magic_link email" do
    subscriber = subscribers(:confirmed)
    subscriber.generate_auth_token!
    mail = SubscriberMailer.magic_link(subscriber)

    assert_equal "Sign in to #{SiteSetting.current.site_name}", mail.subject
    assert_equal [ subscriber.email ], mail.to
    assert_includes mail.body.encoded, subscriber.auth_token
  end

  test "magic_link email uses branding colors" do
    site = SiteSetting.current
    site.update!(email_accent_color: "#00aaff", email_body_text_color: "#334455")
    subscriber = subscribers(:confirmed)
    subscriber.generate_auth_token!
    mail = SubscriberMailer.magic_link(subscriber)

    assert_includes mail.body.encoded, "#00aaff"
    assert_includes mail.body.encoded, "#334455"
  end
end
