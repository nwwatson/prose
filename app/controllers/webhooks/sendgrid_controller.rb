module Webhooks
  class SendgridController < ActionController::API
    before_action :verify_signature

    def create
      events = JSON.parse(request.body.read)
      EmailService::Sendgrid.new(api_key: nil).process_webhook(events)
      head :ok
    rescue JSON::ParserError
      head :bad_request
    end

    private

    def verify_signature
      verification_key = ENV["SENDGRID_WEBHOOK_VERIFICATION_KEY"]
      return if verification_key.blank?

      public_key = SendGrid::EventWebhook.new
      ec_public_key = public_key.convert_public_key_to_ecdsa(verification_key)

      payload = request.body.read
      request.body.rewind
      signature = request.headers["X-Twilio-Email-Event-Webhook-Signature"]
      timestamp = request.headers["X-Twilio-Email-Event-Webhook-Timestamp"]

      unless public_key.verify_signature(ec_public_key, payload, signature, timestamp)
        head :unauthorized
      end
    rescue StandardError => e
      Rails.logger.error("[SendGrid Webhook] Signature verification failed: #{e.message}")
      head :unauthorized
    end
  end
end
