module Admin
  class MembershipTiersController < BaseController
    before_action :set_tier, only: [ :edit, :update, :destroy ]

    def index
      @tiers = MembershipTier.ordered
    end

    def new
      @tier = MembershipTier.new(currency: SiteSetting.current.payments_currency)
    end

    def create
      @tier = MembershipTier.new(tier_params)

      if @tier.save
        redirect_to admin_membership_tiers_path, notice: t("flash.admin.membership_tiers.created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @tier.update(tier_params)
        redirect_to admin_membership_tiers_path, notice: t("flash.admin.membership_tiers.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @tier.destroy
        redirect_to admin_membership_tiers_path, notice: t("flash.admin.membership_tiers.deleted")
      else
        redirect_to admin_membership_tiers_path, alert: t("flash.admin.membership_tiers.has_members")
      end
    end

    private

    def set_tier
      @tier = MembershipTier.find(params[:id])
    end

    def tier_params
      params.require(:membership_tier).permit(:name, :description, :price_cents, :currency, :interval, :active, :position)
    end
  end
end
