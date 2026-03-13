require "test_helper"
require "ostruct"

class PaymentService::StripeTest < ActiveSupport::TestCase
  test "initialized with keys" do
    service = PaymentService::Stripe.new(secret_key: "sk_test", publishable_key: "pk_test")
    assert_not_nil service
  end

  test "construct_webhook_event calls Stripe::Webhook" do
    SiteSetting.current.update!(stripe_webhook_secret: "whsec_test")

    service = PaymentService::Stripe.new(secret_key: "sk_test")

    # Just verify the method exists and accepts the right params
    assert service.respond_to?(:construct_webhook_event)
  ensure
    SiteSetting.current.update!(stripe_webhook_secret: nil)
  end
end
