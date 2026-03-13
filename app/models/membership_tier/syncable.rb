module MembershipTier::Syncable
  extend ActiveSupport::Concern

  included do
    after_save :sync_to_stripe, if: :should_sync_to_stripe?
  end

  def synced_to_stripe?
    stripe_product_id.present? && stripe_price_id.present?
  end

  private

  def should_sync_to_stripe?
    PaymentService.configured? && (stripe_product_id.blank? || stripe_price_id.blank?)
  end

  def sync_to_stripe
    provider = PaymentService.provider

    if stripe_product_id.blank?
      product = provider.create_product(name: name, description: description)
      update_columns(stripe_product_id: product.id)
    end

    if stripe_price_id.blank?
      price = provider.create_price(
        product_id: stripe_product_id,
        amount: price_cents,
        currency: currency,
        interval: interval
      )
      update_columns(stripe_price_id: price.id)
    end
  end
end
