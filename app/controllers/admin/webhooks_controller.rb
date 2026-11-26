module Admin
  class WebhooksController < BaseController
    include Admin::CrudResource

    # require_admin must run before the record is loaded.
    before_action :require_admin
    crud_resource Webhook, member_actions: %i[test regenerate_secret]

    def index
      @webhooks = Webhook.order(created_at: :desc)
    end

    def new
      @webhook = Webhook.new(events: [])
    end

    # The signing secret is shown once, on the edit page.
    def create
      super { flash[:raw_secret] = @webhook.signing_secret }
    end

    def test
      DeliverWebhookJob.perform_later(@webhook.id, "ping", { message: "This is a test delivery from Prose." })
      redirect_to admin_webhook_webhook_deliveries_path(@webhook), notice: t("flash.admin.webhooks.test_sent")
    end

    def regenerate_secret
      @webhook.regenerate_secret!
      flash[:raw_secret] = @webhook.signing_secret
      redirect_to edit_admin_webhook_path(@webhook), notice: t("flash.admin.webhooks.secret_regenerated")
    end

    private

    def after_save_path
      @webhook.previously_new_record? ? edit_admin_webhook_path(@webhook) : super
    end

    def resource_params
      params.require(:webhook).permit(:url, :active, events: [])
    end
  end
end
