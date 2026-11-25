module WebhookDispatcher
  # Enqueues one DeliverWebhookJob per active webhook subscribed to `event`.
  # The payload is given as a block so it's only built (once) when at least
  # one webhook is listening.
  def self.deliver(event)
    webhook_ids = Webhook.active.subscribed_to(event).pluck(:id)
    return if webhook_ids.empty?

    data = yield
    ActiveJob.perform_all_later(webhook_ids.map { |webhook_id| DeliverWebhookJob.new(webhook_id, event, data) })
  end
end
