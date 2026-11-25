require "test_helper"

class EmailService::SendgridTest < ActiveSupport::TestCase
  include EmailProviderHelper

  test "responds to the EmailService::Base adapter interface" do
    provider = EmailService::Sendgrid.new(api_key: "SG.test-key")
    assert provider.respond_to?(:deliver_newsletter)
  end

  test "deliver_newsletter posts the campaign to SendGrid" do
    fake = FakeSendgridClient.new

    with_fake_sendgrid(fake) do
      EmailService::Sendgrid.new(api_key: "SG.test-key").deliver_newsletter(newsletters(:sending_newsletter), subscribers(:confirmed))
    end

    assert_equal [ subscribers(:confirmed).email ], fake.accepted
  end

  test "deliver_newsletter raises DeliveryError on a non-2xx response" do
    fake = FakeSendgridClient.new { 400 }

    with_fake_sendgrid(fake) do
      error = assert_raises(EmailService::DeliveryError) do
        EmailService::Sendgrid.new(api_key: "SG.test-key").deliver_newsletter(newsletters(:sending_newsletter), subscribers(:confirmed))
      end
      assert_equal 400, error.status_code
      assert_not_includes error.message, subscribers(:confirmed).email
    end
  end

  test "reuses one API client across deliveries" do
    fake = FakeSendgridClient.new

    with_fake_sendgrid(fake) do |clients_built|
      provider = EmailService::Sendgrid.new(api_key: "SG.test-key")
      provider.deliver_newsletter(newsletters(:sending_newsletter), subscribers(:confirmed))
      provider.deliver_newsletter(newsletters(:sending_newsletter), subscribers(:confirmed))

      assert_equal 1, clients_built.call
    end
    assert_equal 2, fake.accepted.size
  end
end
