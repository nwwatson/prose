require "test_helper"

class DeliverWebhookJobTest < ActiveJob::TestCase
  def with_sender_post(outcome)
    original = Webhooks::Sender.method(:post)
    Webhooks::Sender.define_singleton_method(:post) do |*_args, **_kwargs|
      case outcome
      when Exception then raise outcome
      when Proc then outcome.call
      else outcome
      end
    end
    yield
  ensure
    Webhooks::Sender.define_singleton_method(:post, original)
  end

  test "records a successful delivery and resets consecutive_failures" do
    webhook = webhooks(:subscriber_events_webhook)
    response = Webhooks::Sender::Response.new(200, "ok")

    with_sender_post(response) do
      DeliverWebhookJob.perform_now(webhook.id, "subscriber.created", { id: 1 })
    end

    webhook.reload
    assert_equal 0, webhook.consecutive_failures
    assert_equal 200, webhook.last_response_code
    delivery = webhook.webhook_deliveries.recent.first
    assert delivery.success?
    assert_equal "subscriber.created", delivery.event
  end

  test "records a failed delivery, increments consecutive_failures, and schedules a retry" do
    webhook = webhooks(:post_events_webhook)
    error = Webhooks::Sender::DeliveryError.new("Webhook endpoint returned 500", response_code: 500)

    with_sender_post(error) do
      assert_enqueued_jobs 1, only: DeliverWebhookJob do
        DeliverWebhookJob.perform_now(webhook.id, "post.published", { id: 1 })
      end
    end

    webhook.reload
    assert_equal 1, webhook.consecutive_failures
    delivery = webhook.webhook_deliveries.recent.first
    assert_not delivery.success?
    assert_equal 500, delivery.response_code
  end

  test "disables the webhook once consecutive failures reach the maximum" do
    webhook = webhooks(:post_events_webhook)
    webhook.update!(consecutive_failures: Webhook::MAX_CONSECUTIVE_FAILURES - 1)
    error = Webhooks::Sender::DeliveryError.new("Webhook endpoint returned 500", response_code: 500)

    with_sender_post(error) do
      DeliverWebhookJob.perform_now(webhook.id, "post.published", { id: 1 })
    end

    assert_not webhook.reload.active?
  end

  test "does nothing when the webhook is inactive" do
    webhook = webhooks(:disabled_webhook)
    called = false

    with_sender_post(->(*) { called = true }) do
      DeliverWebhookJob.perform_now(webhook.id, "comment.created", { id: 1 })
    end

    assert_not called
    assert_equal 0, webhook.webhook_deliveries.count
  end

  test "does nothing when the webhook no longer exists" do
    assert_nothing_raised do
      DeliverWebhookJob.perform_now(0, "post.published", { id: 1 })
    end
  end
end
