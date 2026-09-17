require "test_helper"

class WebhookDispatcherTest < ActiveJob::TestCase
  test "enqueues a delivery job for each active webhook subscribed to the event" do
    webhook = webhooks(:post_events_webhook)

    assert_enqueued_with(job: DeliverWebhookJob, args: [ webhook.id, "post.published", { id: 1 } ]) do
      WebhookDispatcher.deliver("post.published", { id: 1 })
    end
  end

  test "does not enqueue a job for webhooks not subscribed to the event" do
    assert_no_enqueued_jobs only: DeliverWebhookJob do
      WebhookDispatcher.deliver("nonexistent.event", { id: 1 })
    end
  end

  test "does not enqueue a job for inactive webhooks" do
    Webhook.update_all(active: false)
    Webhook.create!(url: "https://example.com/isolated", events: [ "post.published" ], active: false)

    assert_no_enqueued_jobs only: DeliverWebhookJob do
      WebhookDispatcher.deliver("post.published", { id: 1 })
    end
  end
end
