class SyncStripeSubscriptionJob < ApplicationJob
  queue_as :default

  def perform
    return unless PaymentService.configured?

    provider = PaymentService.provider
    Membership.current.where.not(stripe_subscription_id: nil).find_each do |membership|
      sync_membership(provider, membership)
    rescue => e
      Rails.logger.error("[Stripe Sync] Failed to sync membership #{membership.id}: #{e.message}")
    end
  end

  private

  def sync_membership(provider, membership)
    subscription = provider.retrieve_subscription(membership.stripe_subscription_id)

    membership.update!(
      status: map_status(subscription.status),
      current_period_start: Time.at(subscription.current_period_start),
      current_period_end: Time.at(subscription.current_period_end),
      canceled_at: subscription.canceled_at ? Time.at(subscription.canceled_at) : nil
    )
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
