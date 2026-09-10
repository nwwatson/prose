module Admin
  class WebhookDeliveriesController < BaseController
    def index
      @webhook = Webhook.find(params[:webhook_id])
      @webhook_deliveries = @webhook.webhook_deliveries.recent.limit(50)
    end
  end
end
