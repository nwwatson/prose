require "test_helper"

class EmailService::SmtpTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  test "deliver_newsletter enqueues the campaign mailer for the given subscriber" do
    newsletter = newsletters(:sending_newsletter)
    subscriber = subscribers(:confirmed)

    assert_enqueued_email_with NewsletterMailer, :campaign, args: [ subscriber, newsletter ] do
      EmailService::Smtp.new.deliver_newsletter(newsletter, subscriber)
    end
  end

  test "responds to the EmailService::Base adapter interface" do
    assert EmailService::Smtp.new.respond_to?(:deliver_newsletter)
  end
end
