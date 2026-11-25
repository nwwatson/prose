require "test_helper"

class WebhookDispatcherTest < ActiveJob::TestCase
  include BulkEnqueueHelper

  test "enqueues a delivery job for each active webhook subscribed to the event" do
    webhook = webhooks(:post_events_webhook)

    assert_enqueued_with(job: DeliverWebhookJob, args: [ webhook.id, "post.published", { id: 1 } ]) do
      WebhookDispatcher.deliver("post.published") { { id: 1 } }
    end
  end

  test "bulk-enqueues all deliveries at once, each with its own delivery id" do
    Webhook.create!(url: "https://example.com/second", events: [ "post.published" ])
    expected = Webhook.active.subscribed_to("post.published").count

    batches = capture_bulk_enqueues { WebhookDispatcher.deliver("post.published") { { id: 1 } } }

    assert_equal [ expected ], batches.map(&:size)
    job_ids = enqueued_jobs.map { |job| job["job_id"] }
    assert_equal batches.first.map(&:job_id), job_ids
    assert_equal expected, job_ids.uniq.size
  end

  test "retries of a bulk-enqueued delivery keep the same delivery id" do
    delivery_ids = []
    failing_post = ->(*, **options) do
      delivery_ids << options[:delivery_id]
      raise Webhooks::Sender::DeliveryError.new("Webhook endpoint returned 500", response_code: 500)
    end

    WebhookDispatcher.deliver("post.published") { { id: 1 } }
    enqueued_ids = enqueued_jobs.map { |job| job["job_id"] }

    with_singleton_stub(Webhooks::Sender, :post, failing_post) do
      DeliverWebhookJob::MAX_ATTEMPTS.times { perform_enqueued_jobs(only: DeliverWebhookJob) }
    end

    assert_equal({ enqueued_ids.sole => DeliverWebhookJob::MAX_ATTEMPTS }, delivery_ids.tally)
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
