module MembershipTier::Syncable
  extend ActiveSupport::Concern

  included do
    after_commit :enqueue_stripe_sync, on: %i[create update], if: :should_sync_to_stripe?
  end

  def synced_to_stripe?
    stripe_product_id.present? && stripe_price_id.present?
  end

  private

  def should_sync_to_stripe?
    PaymentService.configured? && (stripe_product_id.blank? || stripe_price_id.blank?)
  end

  def enqueue_stripe_sync
    SyncMembershipTierJob.perform_later(self)
  end
end
