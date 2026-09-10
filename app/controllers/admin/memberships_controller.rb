module Admin
  # Not gated by require_payments_configured: comp memberships
  # (Membership.grant_complimentary!) don't require Stripe.
  class MembershipsController < BaseController
    before_action :set_membership, only: [ :show, :destroy ]
    before_action :set_subscriber, only: [ :comp ]

    def index
      @memberships = Membership.by_recency.includes(:subscriber, :membership_tier)
      @memberships = @memberships.where(status: params[:status]) if params[:status].present?
    end

    def show
    end

    def destroy
      @membership.cancel!
      redirect_to admin_memberships_path, notice: t("flash.admin.memberships.canceled")
    end

    def comp
      tier = MembershipTier.find(params[:tier_id])
      Membership.grant_complimentary!(subscriber: @subscriber, membership_tier: tier)

      redirect_to admin_memberships_path, notice: t("flash.admin.memberships.comp_granted")
    end

    private

    def set_membership
      @membership = Membership.find(params[:id])
    end

    def set_subscriber
      @subscriber = Subscriber.find(params[:subscriber_id])
    end
  end
end
