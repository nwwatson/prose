require "test_helper"

class WebhookDispatcherTest < ActiveJob::TestCase
  test "enqueues a delivery job for each active webhook subscribed to the event" do
    webhook = webhooks(:post_events_webhook)

    assert_enqueued_with(job: DeliverWebhookJob, args: [ webhook.id, "post.published", { id: 1 } ]) do
      WebhookDispatcher.deliver("post.published") { { id: 1 } }
    end
  end

  test "does not enqueue a job for webhooks not subscribed to the event" do
    assert_no_enqueued_jobs only: DeliverWebhookJob do
      WebhookDispatcher.deliver("nonexistent.event") { { id: 1 } }
    end
  end

  test "does not enqueue a job for inactive webhooks" do
    Webhook.update_all(active: false)
    Webhook.create!(url: "https://example.com/isolated", events: [ "post.published" ], active: false)

    assert_no_enqueued_jobs only: DeliverWebhookJob do
      WebhookDispatcher.deliver("post.published") { { id: 1 } }
    end
  end

  test "builds the payload once, and only when a webhook is subscribed" do
    Webhook.create!(url: "https://example.com/second", events: [ "post.published" ])
    calls = 0

    WebhookDispatcher.deliver("post.published") { calls += 1; { id: 1 } }
    assert_equal 1, calls

    WebhookDispatcher.deliver("subscriber.deleted.never") { calls += 1 }
    Webhook.update_all(active: false)
    WebhookDispatcher.deliver("post.published") { calls += 1 }
    assert_equal 1, calls
  end

  test "subscribed_to matches exact event names in the events array" do
    assert_includes Webhook.subscribed_to("post.updated"), webhooks(:post_events_webhook)
    assert_not_includes Webhook.subscribed_to("post.updated"), webhooks(:subscriber_events_webhook)
    assert_empty Webhook.subscribed_to("post")
  end
end
