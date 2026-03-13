require "test_helper"

class Webhooks::StripeControllerTest < ActionDispatch::IntegrationTest
  test "POST create returns bad_request for invalid signature" do
    SiteSetting.current.update!(stripe_secret_key: "sk_test", stripe_publishable_key: "pk_test", stripe_webhook_secret: "whsec_test")

    post webhooks_stripe_path,
      params: "{}",
      headers: { "Stripe-Signature" => "invalid", "CONTENT_TYPE" => "application/json" }
    assert_response :bad_request
  ensure
    SiteSetting.current.update!(stripe_secret_key: nil, stripe_publishable_key: nil, stripe_webhook_secret: nil)
  end
end
