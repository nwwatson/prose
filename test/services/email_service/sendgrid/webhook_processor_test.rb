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

  test "open events increment open_count in the database, not from a stale record" do
    delivery = newsletter_deliveries(:sent_to_confirmed)
    stale = NewsletterDelivery.find(delivery.id)
    event = event_for(delivery, "open")

    # Both events see the record as it was before either one was written.
    with_singleton_stub(NewsletterDelivery, :find_by, ->(*) { stale }) do
      travel_to(2.hours.ago) { @processor.process(event) }
      @processor.process(event)
    end
    delivery.reload

    assert_equal 2, delivery.open_count
    assert_operator delivery.opened_at, :<, 1.hour.ago
  end

  test "open events count from zero when open_count is null" do
    delivery = newsletter_deliveries(:sent_to_confirmed)
    delivery.update_columns(open_count: nil)

    @processor.process(event_for(delivery, "open"))

    assert_equal 1, delivery.reload.open_count
  end

  test "a concurrent click event keeps the first clicked_at" do
    delivery = newsletter_deliveries(:sent_to_confirmed)
    stale = NewsletterDelivery.find(delivery.id)
    event = event_for(delivery, "click")

    with_singleton_stub(NewsletterDelivery, :find_by, ->(*) { stale }) do
      travel_to(2.hours.ago) { @processor.process(event) }
      @processor.process(event)
    end

    assert_operator delivery.reload.clicked_at, :<, 1.hour.ago
  end

  private

  def event_for(delivery, type)
    {
      "event" => type,
      "unique_args" => { "newsletter_id" => delivery.newsletter_id.to_s, "subscriber_id" => delivery.subscriber_id.to_s }
    }
  end
end
