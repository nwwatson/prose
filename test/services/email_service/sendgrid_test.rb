require "test_helper"

class EmailService::SendgridTest < ActiveSupport::TestCase
  setup do
    @provider = EmailService::Sendgrid.new(api_key: "SG.test-key")
  end

  test "process_webhook updates opened_at on open event" do
    delivery = newsletter_deliveries(:sent_to_confirmed)
    newsletter = delivery.newsletter
    subscriber = delivery.subscriber

    events = [ {
      "event" => "open",
      "unique_args" => { "newsletter_id" => newsletter.id.to_s, "subscriber_id" => subscriber.id.to_s }
    } ]

    @provider.process_webhook(events)
    delivery.reload

    assert_not_nil delivery.opened_at
    assert_equal 1, delivery.open_count
  end

  test "process_webhook increments open_count on repeat opens" do
    delivery = newsletter_deliveries(:opened_delivery)
    newsletter = delivery.newsletter
    subscriber = delivery.subscriber
    original_count = delivery.open_count

    events = [ {
      "event" => "open",
      "unique_args" => { "newsletter_id" => newsletter.id.to_s, "subscriber_id" => subscriber.id.to_s }
    } ]

    @provider.process_webhook(events)
    delivery.reload

    assert_equal original_count + 1, delivery.open_count
  end

  test "process_webhook updates clicked_at on click event" do
    delivery = newsletter_deliveries(:sent_to_confirmed)
    newsletter = delivery.newsletter
    subscriber = delivery.subscriber

    events = [ {
      "event" => "click",
      "unique_args" => { "newsletter_id" => newsletter.id.to_s, "subscriber_id" => subscriber.id.to_s }
    } ]

    @provider.process_webhook(events)
    delivery.reload

    assert_not_nil delivery.clicked_at
  end

  test "process_webhook updates bounced_at on bounce event" do
    delivery = newsletter_deliveries(:sent_to_confirmed)
    newsletter = delivery.newsletter
    subscriber = delivery.subscriber

    events = [ {
      "event" => "bounce",
      "unique_args" => { "newsletter_id" => newsletter.id.to_s, "subscriber_id" => subscriber.id.to_s }
    } ]

    @provider.process_webhook(events)
    delivery.reload

    assert_not_nil delivery.bounced_at
  end

  test "process_webhook handles spamreport by unsubscribing" do
    delivery = newsletter_deliveries(:sent_to_confirmed)
    newsletter = delivery.newsletter
    subscriber = delivery.subscriber

    events = [ {
      "event" => "spamreport",
      "unique_args" => { "newsletter_id" => newsletter.id.to_s, "subscriber_id" => subscriber.id.to_s }
    } ]

    @provider.process_webhook(events)
    subscriber.reload

    assert subscriber.unsubscribed?
  end

  test "process_webhook ignores events with missing delivery" do
    events = [ {
      "event" => "open",
      "unique_args" => { "newsletter_id" => "999999", "subscriber_id" => "999999" }
    } ]

    assert_nothing_raised { @provider.process_webhook(events) }
  end

  test "process_webhook handles multiple events" do
    delivery = newsletter_deliveries(:sent_to_confirmed)
    newsletter = delivery.newsletter
    subscriber = delivery.subscriber

    events = [
      { "event" => "open", "unique_args" => { "newsletter_id" => newsletter.id.to_s, "subscriber_id" => subscriber.id.to_s } },
      { "event" => "click", "unique_args" => { "newsletter_id" => newsletter.id.to_s, "subscriber_id" => subscriber.id.to_s } }
    ]

    @provider.process_webhook(events)
    delivery.reload

    assert_not_nil delivery.opened_at
    assert_not_nil delivery.clicked_at
  end
end
