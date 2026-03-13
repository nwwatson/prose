module Webhooks
  class StripeController < ActionController::API
    def create
      payload = request.body.read
      signature = request.headers["Stripe-Signature"]

      event = PaymentService.provider.construct_webhook_event(
        payload: payload,
        signature: signature
      )

      StripeWebhookJob.perform_later(event.type, event.data.object.to_hash.deep_stringify_keys)
      head :ok
    rescue ::Stripe::SignatureVerificationError => e
      Rails.logger.error("[Stripe Webhook] Signature verification failed: #{e.message}")
      head :bad_request
    rescue JSON::ParserError
      head :bad_request
    end
  end
end
