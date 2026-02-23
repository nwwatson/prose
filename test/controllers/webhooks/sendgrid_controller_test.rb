require "test_helper"

class Webhooks::SendgridControllerTest < ActionDispatch::IntegrationTest
  test "POST create processes events and returns 200" do
    delivery = newsletter_deliveries(:sent_to_confirmed)
    newsletter = delivery.newsletter
    subscriber = delivery.subscriber

    events = [ {
      "event" => "open",
      "unique_args" => { "newsletter_id" => newsletter.id.to_s, "subscriber_id" => subscriber.id.to_s }
    } ]

    post webhooks_sendgrid_path,
      params: events.to_json,
      headers: { "Content-Type" => "application/json" }

    assert_response :ok
    assert_not_nil delivery.reload.opened_at
  end

  test "POST create returns 200 even for unknown events" do
    events = [ { "event" => "unknown", "unique_args" => { "newsletter_id" => "1", "subscriber_id" => "1" } } ]

    post webhooks_sendgrid_path,
      params: events.to_json,
      headers: { "Content-Type" => "application/json" }

    assert_response :ok
  end

  test "POST create returns bad request for invalid JSON" do
    post webhooks_sendgrid_path,
      params: "not json",
      headers: { "Content-Type" => "application/json" }

    assert_response :bad_request
  end

  test "POST create handles bounce event" do
    delivery = newsletter_deliveries(:sent_to_confirmed)
    newsletter = delivery.newsletter
    subscriber = delivery.subscriber

    events = [ {
      "event" => "bounce",
      "unique_args" => { "newsletter_id" => newsletter.id.to_s, "subscriber_id" => subscriber.id.to_s }
    } ]

    post webhooks_sendgrid_path,
      params: events.to_json,
      headers: { "Content-Type" => "application/json" }

    assert_response :ok
    assert_not_nil delivery.reload.bounced_at
  end
end
