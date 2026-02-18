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

  test "magic_link email" do
    subscriber = subscribers(:confirmed)
    subscriber.generate_auth_token!
    mail = SubscriberMailer.magic_link(subscriber)

    assert_equal "Sign in to #{SiteSetting.current.site_name}", mail.subject
    assert_equal [ subscriber.email ], mail.to
    assert_includes mail.body.encoded, subscriber.auth_token
  end
end
