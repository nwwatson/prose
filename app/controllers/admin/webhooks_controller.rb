module Admin
  class WebhooksController < BaseController
    before_action :set_webhook, only: [ :show, :edit, :update, :destroy, :test, :regenerate_secret ]

    def index
      @webhooks = Webhook.order(created_at: :desc)
    end

    def show
      redirect_to edit_admin_webhook_path(@webhook)
    end

    def new
      @webhook = Webhook.new(events: [])
    end

    def create
      @webhook = Webhook.new(webhook_params)

      if @webhook.save
        flash[:raw_secret] = @webhook.signing_secret
        redirect_to edit_admin_webhook_path(@webhook), notice: t("flash.admin.webhooks.created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @webhook.update(webhook_params)
        redirect_to admin_webhooks_path, notice: t("flash.admin.webhooks.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @webhook.destroy
      redirect_to admin_webhooks_path, notice: t("flash.admin.webhooks.deleted")
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

    def set_webhook
      @webhook = Webhook.find(params[:id])
    end

    def webhook_params
      params.require(:webhook).permit(:url, :active, events: [])
    end
  end
end
