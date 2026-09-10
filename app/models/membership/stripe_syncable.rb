module Membership::StripeSyncable
  extend ActiveSupport::Concern

  STRIPE_STATUS_MAP = {
    "active" => :active,
    "past_due" => :past_due,
    "canceled" => :canceled,
    "incomplete" => :incomplete,
    "trialing" => :trialing
  }.freeze

  class_methods do
    def status_from_stripe(stripe_status)
      STRIPE_STATUS_MAP.fetch(stripe_status, :incomplete)
    end

    # session_data: string-keyed Hash from a Stripe checkout.session.completed event
    # subscription: the Stripe::Subscription retrieved for that session
    def activate_from_checkout!(session_data, subscription)
      return unless session_data["mode"] == "subscription"

      customer_email = session_data.dig("customer_details", "email") || session_data["customer_email"]
      subscriber = Subscriber.find_by(email: customer_email&.downcase)
      return unless subscriber

      price_id = subscription.items.data.first.price.id
      tier = MembershipTier.find_by(stripe_price_id: price_id)
      return unless tier

      membership = find_or_create_by!(stripe_subscription_id: session_data["subscription"]) do |m|
        m.subscriber = subscriber
        m.membership_tier = tier
        m.stripe_customer_id = session_data["customer"]
        m.status = status_from_stripe(stripe_value(subscription, :status))
      end

      membership.sync_from_stripe!(subscription)
      membership
    end

    def stripe_value(subscription, key)
      subscription.is_a?(Hash) ? subscription[key.to_s] : subscription.public_send(key)
    end
  end

  # subscription: a Stripe::Subscription object or a string-keyed Hash (webhook payload).
  # Missing period fields leave the existing stored values untouched; canceled_at always
  # reflects the given value (including clearing it back to nil) since Stripe always sends it.
  def sync_from_stripe!(subscription)
    attrs = { status: self.class.status_from_stripe(stripe_value(subscription, :status)) }

    if (period_start = stripe_value(subscription, :current_period_start))
      attrs[:current_period_start] = Time.at(period_start)
    end

    if (period_end = stripe_value(subscription, :current_period_end))
      attrs[:current_period_end] = Time.at(period_end)
    end

    canceled_at = stripe_value(subscription, :canceled_at)
    attrs[:canceled_at] = canceled_at ? Time.at(canceled_at) : nil

    update!(attrs)
  end

  private

  def stripe_value(subscription, key)
    self.class.stripe_value(subscription, key)
  end
end
