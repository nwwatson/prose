require "test_helper"

class EmailService::Sendgrid::WebhookProcessorTest < ActiveSupport::TestCase
  setup do
    @processor = EmailService::Sendgrid::WebhookProcessor.new
  end

  test "process updates opened_at on open event" do
    delivery = newsletter_deliveries(:sent_to_confirmed)
    newsletter = delivery.newsletter
    subscriber = delivery.subscriber

    events = [ {
      "event" => "open",
      "unique_args" => { "newsletter_id" => newsletter.id.to_s, "subscriber_id" => subscriber.id.to_s }
    } ]

    @processor.process(events)
    delivery.reload

    assert_not_nil delivery.opened_at
    assert_equal 1, delivery.open_count
  end

  test "process increments open_count on repeat opens" do
    delivery = newsletter_deliveries(:opened_delivery)
    newsletter = delivery.newsletter
    subscriber = delivery.subscriber
    original_count = delivery.open_count

    events = [ {
      "event" => "open",
      "unique_args" => { "newsletter_id" => newsletter.id.to_s, "subscriber_id" => subscriber.id.to_s }
    } ]

    @processor.process(events)
    delivery.reload

    assert_equal original_count + 1, delivery.open_count
  end

  test "process updates clicked_at on click event" do
    delivery = newsletter_deliveries(:sent_to_confirmed)
    newsletter = delivery.newsletter
    subscriber = delivery.subscriber

    events = [ {
      "event" => "click",
      "unique_args" => { "newsletter_id" => newsletter.id.to_s, "subscriber_id" => subscriber.id.to_s }
    } ]

    @processor.process(events)
    delivery.reload

    assert_not_nil delivery.clicked_at
  end

  test "process updates bounced_at on bounce event" do
    delivery = newsletter_deliveries(:sent_to_confirmed)
    newsletter = delivery.newsletter
    subscriber = delivery.subscriber

    events = [ {
      "event" => "bounce",
      "unique_args" => { "newsletter_id" => newsletter.id.to_s, "subscriber_id" => subscriber.id.to_s }
    } ]

    @processor.process(events)
    delivery.reload

    assert_not_nil delivery.bounced_at
  end

  test "process handles spamreport by unsubscribing" do
    delivery = newsletter_deliveries(:sent_to_confirmed)
    newsletter = delivery.newsletter
    subscriber = delivery.subscriber

    events = [ {
      "event" => "spamreport",
      "unique_args" => { "newsletter_id" => newsletter.id.to_s, "subscriber_id" => subscriber.id.to_s }
    } ]

    @processor.process(events)
    subscriber.reload

    assert subscriber.unsubscribed?
  end

  test "process ignores events with missing delivery" do
    events = [ {
      "event" => "open",
      "unique_args" => { "newsletter_id" => "999999", "subscriber_id" => "999999" }
    } ]

    assert_nothing_raised { @processor.process(events) }
  end

  test "process handles multiple events" do
    delivery = newsletter_deliveries(:sent_to_confirmed)
    newsletter = delivery.newsletter
    subscriber = delivery.subscriber

    events = [
      { "event" => "open", "unique_args" => { "newsletter_id" => newsletter.id.to_s, "subscriber_id" => subscriber.id.to_s } },
      { "event" => "click", "unique_args" => { "newsletter_id" => newsletter.id.to_s, "subscriber_id" => subscriber.id.to_s } }
    ]

    @processor.process(events)
    delivery.reload

    assert_not_nil delivery.opened_at
    assert_not_nil delivery.clicked_at
  end

  test "process accepts a single event hash" do
    delivery = newsletter_deliveries(:sent_to_confirmed)
    newsletter = delivery.newsletter
    subscriber = delivery.subscriber

    event = {
      "event" => "open",
      "unique_args" => { "newsletter_id" => newsletter.id.to_s, "subscriber_id" => subscriber.id.to_s }
    }

    @processor.process(event)
    delivery.reload

    assert_not_nil delivery.opened_at
  end
end
