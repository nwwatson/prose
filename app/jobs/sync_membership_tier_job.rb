class SyncMembershipTierJob < ApplicationJob
  queue_as :default

  def perform(tier)
    return unless PaymentService.configured?

    provider = PaymentService.provider

    if tier.stripe_product_id.blank?
      product = provider.create_product(name: tier.name, description: tier.description)
      tier.update_columns(stripe_product_id: product.id)
    end

    if tier.stripe_price_id.blank?
      price = provider.create_price(
        product_id: tier.stripe_product_id,
        amount: tier.price_cents,
        currency: tier.currency,
        interval: tier.interval
      )
      tier.update_columns(stripe_price_id: price.id)
    end

    broadcast_synced(tier)
  end

  private

  def broadcast_synced(tier)
    Turbo::StreamsChannel.broadcast_replace_to(
      "membership_tiers",
      target: "membership_tier_#{tier.id}_card",
      partial: "admin/membership_tiers/tier_card",
      locals: { tier: tier.reload, member_count: MembershipTier.current_member_counts.fetch(tier.id, 0) }
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      "membership_tiers",
      target: "membership_tier_#{tier.id}_row",
      partial: "admin/membership_tiers/tier_row",
      locals: { tier: tier.reload, member_count: MembershipTier.current_member_counts.fetch(tier.id, 0) }
    )
  end
end
