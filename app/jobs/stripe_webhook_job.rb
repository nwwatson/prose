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

    customer_email = data["customer_details"]["email"] || data["customer_email"]
    subscription_id = data["subscription"]
    customer_id = data["customer"]

    subscriber = Subscriber.find_by(email: customer_email&.downcase)
    return unless subscriber

    subscription = PaymentService.provider.retrieve_subscription(subscription_id)
    price_id = subscription.items.data.first.price.id
    tier = MembershipTier.find_by(stripe_price_id: price_id)
    return unless tier

    Membership.find_or_create_by!(stripe_subscription_id: subscription_id) do |m|
      m.subscriber = subscriber
      m.membership_tier = tier
      m.stripe_customer_id = customer_id
      m.status = map_status(subscription.status)
      m.current_period_start = Time.at(subscription.current_period_start)
      m.current_period_end = Time.at(subscription.current_period_end)
    end
  end

  def handle_subscription_updated(data)
    membership = Membership.find_by(stripe_subscription_id: data["id"])
    return unless membership

    membership.update!(
      status: map_status(data["status"]),
      current_period_start: data["current_period_start"] ? Time.at(data["current_period_start"]) : membership.current_period_start,
      current_period_end: data["current_period_end"] ? Time.at(data["current_period_end"]) : membership.current_period_end,
      canceled_at: data["canceled_at"] ? Time.at(data["canceled_at"]) : nil
    )
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

  def map_status(stripe_status)
    case stripe_status
    when "active" then :active
    when "past_due" then :past_due
    when "canceled" then :canceled
    when "incomplete" then :incomplete
    when "trialing" then :trialing
    else :incomplete
    end
  end
end
