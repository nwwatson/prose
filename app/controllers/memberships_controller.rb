class MembershipsController < ApplicationController
  before_action :require_payments_configured

  def index
    @tiers = MembershipTier.active.ordered
  end

  def checkout
    tier = MembershipTier.active.find(params[:tier_id])
    subscriber = current_subscriber

    unless subscriber&.confirmed?
      redirect_to memberships_path, alert: t("flash.memberships.sign_in_required")
      return
    end

    provider = PaymentService.provider
    session = provider.create_checkout_session(
      price_id: tier.stripe_price_id,
      customer_email: subscriber.email,
      customer_id: subscriber.stripe_customer_id,
      success_url: success_memberships_url(session_id: "{CHECKOUT_SESSION_ID}"),
      cancel_url: memberships_url
    )

    redirect_to session.url, allow_other_host: true
  end

  def success
    @tier = nil
  end

  def portal
    subscriber = current_subscriber
    customer_id = subscriber&.stripe_customer_id

    unless customer_id.present?
      redirect_to memberships_path, alert: t("flash.memberships.no_subscription")
      return
    end

    provider = PaymentService.provider
    session = provider.create_portal_session(
      customer_id: customer_id,
      return_url: memberships_url
    )

    redirect_to session.url, allow_other_host: true
  end

  private

  def require_payments_configured
    redirect_to root_path unless payments_configured?
  end
end
