require "test_helper"

class WebhookDeliveryTest < ActiveSupport::TestCase
  test "valid webhook delivery" do
    delivery = WebhookDelivery.new(
      webhook: webhooks(:post_events_webhook),
      event: "post.published",
      payload: { id: 1 },
      attempted_at: Time.current
    )
    assert delivery.valid?
  end

  test "requires event" do
    delivery = WebhookDelivery.new(webhook: webhooks(:post_events_webhook), attempted_at: Time.current)
    assert_not delivery.valid?
    assert_includes delivery.errors[:event], "can't be blank"
  end

  test "recent scope orders by attempted_at descending" do
    deliveries = WebhookDelivery.recent
    assert_equal webhook_deliveries(:failed_delivery), deliveries.first
  end
end
