require "test_helper"

class WebhookTest < ActiveSupport::TestCase
  test "valid webhook" do
    webhook = Webhook.new(url: "https://example.com/hook", events: [ "post.published" ])
    assert webhook.valid?
  end

  test "requires url" do
    webhook = Webhook.new(events: [ "post.published" ])
    assert_not webhook.valid?
    assert_includes webhook.errors[:url], "can't be blank"
  end

  test "requires url to start with http or https" do
    webhook = Webhook.new(url: "ftp://example.com", events: [ "post.published" ])
    assert_not webhook.valid?
  end

  test "requires at least one event" do
    webhook = Webhook.new(url: "https://example.com/hook", events: [])
    assert_not webhook.valid?
    assert_includes webhook.errors[:events], "can't be blank"
  end

  test "rejects unknown event types" do
    webhook = Webhook.new(url: "https://example.com/hook", events: [ "post.published", "bogus.event" ])
    assert_not webhook.valid?
    assert webhook.errors[:events].any? { |message| message.include?("bogus.event") }
  end

  test "generates a signing secret on create" do
    webhook = Webhook.create!(url: "https://example.com/hook", events: [ "post.published" ])
    assert webhook.signing_secret.present?
  end

  test "signing secret is encrypted at rest" do
    webhook = Webhook.create!(url: "https://example.com/hook", events: [ "post.published" ])
    raw_value = ActiveRecord::Base.connection.select_value("SELECT signing_secret FROM webhooks WHERE id = #{webhook.id}")
    assert_not_equal webhook.signing_secret, raw_value
  end

  test "active scope only includes active webhooks" do
    assert_includes Webhook.active, webhooks(:post_events_webhook)
    assert_not_includes Webhook.active, webhooks(:disabled_webhook)
  end

  test "subscribed_to? checks event membership" do
    webhook = webhooks(:post_events_webhook)
    assert webhook.subscribed_to?("post.published")
    assert_not webhook.subscribed_to?("comment.created")
  end

  test "record_delivery_result! resets consecutive_failures on success" do
    webhook = webhooks(:subscriber_events_webhook)
    webhook.record_delivery_result!(success: true, response_code: 200)
    assert_equal 0, webhook.consecutive_failures
    assert_equal 200, webhook.last_response_code
  end

  test "record_delivery_result! increments consecutive_failures on failure" do
    webhook = webhooks(:post_events_webhook)
    webhook.record_delivery_result!(success: false, response_code: 500)
    assert_equal 1, webhook.consecutive_failures
  end

  test "record_delivery_result! disables webhook after max consecutive failures" do
    webhook = webhooks(:post_events_webhook)
    webhook.update!(consecutive_failures: Webhook::MAX_CONSECUTIVE_FAILURES - 1)

    webhook.record_delivery_result!(success: false, response_code: 500)

    assert_not webhook.active?
  end

  test "regenerate_secret! changes the signing secret" do
    webhook = webhooks(:post_events_webhook)
    original_secret = webhook.signing_secret

    webhook.regenerate_secret!

    assert_not_equal original_secret, webhook.signing_secret
  end
end
