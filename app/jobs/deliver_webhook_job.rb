class DeliverWebhookJob < ApplicationJob
  MAX_ATTEMPTS = 3

  queue_as :default

  # Every attempt is already recorded in the delivery log, so once retries are
  # exhausted the error is swallowed rather than left as a failed job.
  retry_on Webhooks::Sender::DeliveryError, wait: :polynomially_longer, attempts: MAX_ATTEMPTS do |_job, _error|
  end

  def perform(webhook_id, event, data)
    webhook = Webhook.find_by(id: webhook_id)
    return unless webhook&.active?

    envelope = { event: event, timestamp: Time.current.iso8601, data: data }.to_json

    begin
      response = Webhooks::Sender.post(webhook.url, body: envelope, secret: webhook.signing_secret, event: event, delivery_id: job_id)
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
    webhook.prune_deliveries!
    webhook.record_delivery_result!(success: success, response_code: response_code, count_failure: executions >= MAX_ATTEMPTS)
  end
end
