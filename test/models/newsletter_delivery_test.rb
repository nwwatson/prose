require "test_helper"

class NewsletterDeliveryTest < ActiveSupport::TestCase
  test "tracking columns default values" do
    delivery = newsletter_deliveries(:sent_to_confirmed)
    assert_nil delivery.opened_at
    assert_nil delivery.clicked_at
    assert_nil delivery.bounced_at
    assert_equal 0, delivery.open_count
  end

  test "can update opened_at and open_count" do
    delivery = newsletter_deliveries(:sent_to_confirmed)
    delivery.update!(opened_at: Time.current, open_count: 1)
    assert_not_nil delivery.opened_at
    assert_equal 1, delivery.open_count
  end

  test "can update clicked_at" do
    delivery = newsletter_deliveries(:sent_to_confirmed)
    delivery.update!(clicked_at: Time.current)
    assert_not_nil delivery.clicked_at
  end

  test "can update bounced_at" do
    delivery = newsletter_deliveries(:sent_to_confirmed)
    delivery.update!(bounced_at: Time.current)
    assert_not_nil delivery.bounced_at
  end

  test "opened delivery has tracking data" do
    delivery = newsletter_deliveries(:opened_delivery)
    assert_not_nil delivery.opened_at
    assert delivery.open_count > 0
  end

  test "clicked delivery has click data" do
    delivery = newsletter_deliveries(:clicked_delivery)
    assert_not_nil delivery.clicked_at
  end

  test "bounced delivery has bounce data" do
    delivery = newsletter_deliveries(:bounced_delivery)
    assert_not_nil delivery.bounced_at
  end
end
