require "test_helper"

class EmailService::SmtpTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper
  include EmailProviderHelper

  setup { ActionMailer::Base.deliveries.clear }

  test "deliver_newsletter delivers the campaign immediately rather than queueing it" do
    newsletter = newsletters(:sending_newsletter)
    subscriber = subscribers(:confirmed)

    assert_no_enqueued_emails do
      assert_emails 1 do
        EmailService::Smtp.new.deliver_newsletter(newsletter, subscriber)
      end
    end

    mail = ActionMailer::Base.deliveries.last
    assert_equal [ subscriber.email ], mail.to
    assert_equal newsletter.title, mail.subject
  end

  test "deliver_newsletter raises when the server rejects the message, even with raise_delivery_errors off" do
    original = ActionMailer::Base.raise_delivery_errors
    ActionMailer::Base.raise_delivery_errors = false

    with_smtp_rejecting(->(_to) { true }) do
      assert_raises(Net::SMTPFatalError) do
        EmailService::Smtp.new.deliver_newsletter(newsletters(:sending_newsletter), subscribers(:confirmed))
      end
    end
  ensure
    ActionMailer::Base.raise_delivery_errors = original
  end

  test "responds to the EmailService::Base adapter interface" do
    assert EmailService::Smtp.new.respond_to?(:deliver_newsletter)
  end
end
