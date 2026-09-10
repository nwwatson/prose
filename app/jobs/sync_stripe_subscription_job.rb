class SyncStripeSubscriptionJob < ApplicationJob
  queue_as :default

  def perform
    return unless PaymentService.configured?

    provider = PaymentService.provider
    Membership.current.where.not(stripe_subscription_id: nil).find_each do |membership|
      subscription = provider.retrieve_subscription(membership.stripe_subscription_id)
      membership.sync_from_stripe!(subscription)
    rescue => e
      Rails.logger.error("[Stripe Sync] Failed to sync membership #{membership.id}: #{e.message}")
    end
  end
end
