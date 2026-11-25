module Admin
  # Not gated by require_payments_configured: tiers can be viewed/managed
  # before Stripe keys are added, since saving a tier is what triggers the
  # initial sync (see MembershipTier::Syncable).
  class MembershipTiersController < BaseController
    include Admin::CrudResource
    crud_resource MembershipTier, as: :tier

    def index
      @tiers = MembershipTier.ordered
      @member_counts = MembershipTier.current_member_counts
    end

    def new
      @tier = MembershipTier.new(currency: SiteSetting.current.payments_currency)
    end

    # A tier with members refuses to be destroyed.
    def destroy
      if @tier.destroy
        redirect_to index_path, notice: crud_notice(:deleted)
      else
        redirect_to index_path, alert: t("flash.admin.membership_tiers.has_members")
      end
    end

    private

    def resource_params
      params.require(:membership_tier).permit(:name, :description, :price_cents, :currency, :interval, :active, :position)
    end
  end
end
