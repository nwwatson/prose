class DeliverWebhookJob < ApplicationJob
  queue_as :default

  retry_on Webhooks::Sender::DeliveryError, wait: :polynomially_longer, attempts: 3

  def perform(webhook_id, event, data)
    webhook = Webhook.find_by(id: webhook_id)
    return unless webhook&.active?

    envelope = { event: event, timestamp: Time.current.iso8601, data: data }.to_json

    begin
      response = Webhooks::Sender.post(webhook.url, body: envelope, secret: webhook.signing_secret)
      log_delivery!(webhook, event, data, response_code: response.code, success: true)
    rescue Webhooks::Sender::DeliveryError => e
      log_delivery!(webhook, event, data, response_code: e.response_code, success: false, error_message: e.message)
      raise
    end
  end

  private

  def log_delivery!(webhook, event, data, response_code:, success:, error_message: nil)
    webhook.webhook_deliveries.create!(
      event: event,
      payload: data,
      response_code: response_code,
      success: success,
      error_message: error_message,
      attempted_at: Time.current
    )
    webhook.record_delivery_result!(success: success, response_code: response_code)
  end
end
