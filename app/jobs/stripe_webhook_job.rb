class StripeWebhookJob < ApplicationJob
  queue_as :default

  def perform(event_type, event_data)
    case event_type
    when "checkout.session.completed"
      handle_checkout_completed(event_data)
    when "customer.subscription.updated"
      handle_subscription_updated(event_data)
    when "customer.subscription.deleted"
      handle_subscription_deleted(event_data)
    when "invoice.payment_failed"
      handle_payment_failed(event_data)
    end
  end

  private

  def handle_checkout_completed(data)
    return unless data["mode"] == "subscription"

    subscription = PaymentService.provider.retrieve_subscription(data["subscription"])
    Membership.activate_from_checkout!(data, subscription)
  end

  def handle_subscription_updated(data)
    membership = Membership.find_by(stripe_subscription_id: data["id"])
    return unless membership

    membership.sync_from_stripe!(data)
  end

  def handle_subscription_deleted(data)
    membership = Membership.find_by(stripe_subscription_id: data["id"])
    return unless membership

    membership.update!(status: :canceled, canceled_at: Time.current)
  end

  def handle_payment_failed(data)
    subscription_id = data["subscription"]
    membership = Membership.find_by(stripe_subscription_id: subscription_id)
    return unless membership

    membership.update!(status: :past_due)
  end
end
