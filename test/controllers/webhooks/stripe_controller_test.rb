require "test_helper"

class Webhooks::StripeControllerTest < ActionDispatch::IntegrationTest
  test "POST create returns bad_request for invalid signature" do
    configure_stripe!(stripe_webhook_secret: "whsec_test")

    post webhooks_stripe_path,
      params: "{}",
      headers: { "Stripe-Signature" => "invalid", "CONTENT_TYPE" => "application/json" }
    assert_response :bad_request
  end
end
