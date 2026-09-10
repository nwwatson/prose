require "test_helper"
require "ostruct"

class PaymentService::StripeTest < ActiveSupport::TestCase
  test "initialized with keys" do
    service = PaymentService::Stripe.new(secret_key: "sk_test", publishable_key: "pk_test")
    assert_not_nil service
  end

  test "construct_webhook_event uses the injected webhook secret" do
    service = PaymentService::Stripe.new(secret_key: "sk_test", webhook_secret: "whsec_test")

    assert_raises(Stripe::SignatureVerificationError) do
      service.construct_webhook_event(payload: "{}", signature: "invalid")
    end
  end

  test "responds to the PaymentService::Base adapter interface" do
    service = PaymentService::Stripe.new(secret_key: "sk_test")
    assert service.respond_to?(:construct_webhook_event)
    assert service.respond_to?(:create_customer)
  end
end
