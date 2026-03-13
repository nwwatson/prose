module Admin
  class MembershipsController < BaseController
    before_action :set_membership, only: [ :show, :destroy, :comp ]

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
      subscriber = Subscriber.find(params[:subscriber_id] || params[:id])
      tier = MembershipTier.find(params[:tier_id])

      Membership.create!(
        subscriber: subscriber,
        membership_tier: tier,
        status: :active,
        current_period_start: Time.current,
        current_period_end: 100.years.from_now
      )

      redirect_to admin_memberships_path, notice: t("flash.admin.memberships.comp_granted")
    end

    private

    def set_membership
      @membership = Membership.find(params[:id])
    end
  end
end
