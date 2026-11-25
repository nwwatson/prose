module WebhookDispatcher
  # Enqueues one DeliverWebhookJob per active webhook subscribed to `event`.
  # The payload is given as a block so it's only built (once) when at least
  # one webhook is listening.
  def self.deliver(event)
    webhook_ids = Webhook.active.subscribed_to(event).pluck(:id)
    return if webhook_ids.empty?

    data = yield
    webhook_ids.each { |webhook_id| DeliverWebhookJob.perform_later(webhook_id, event, data) }
  end
end
