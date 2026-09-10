require "test_helper"

class EmailService::SendgridTest < ActiveSupport::TestCase
  test "initializes with an api key" do
    provider = EmailService::Sendgrid.new(api_key: "SG.test-key")
    assert_not_nil provider
  end

  test "responds to the EmailService::Base adapter interface" do
    provider = EmailService::Sendgrid.new(api_key: "SG.test-key")
    assert provider.respond_to?(:deliver_newsletter)
  end
end
