module WebhookDispatcher
  def self.deliver(event, data)
    Webhook.active.find_each do |webhook|
      DeliverWebhookJob.perform_later(webhook.id, event, data) if webhook.subscribed_to?(event)
    end
  end
end
