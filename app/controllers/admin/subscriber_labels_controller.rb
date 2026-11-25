module Admin
  class SubscriberLabelsController < BaseController
    include Admin::CrudResource
    crud_resource SubscriberLabel, as: :label

    def index
      @labels = SubscriberLabel.ordered
      @subscriber_counts = SubscriberLabel.subscriber_counts
    end

    private

    def resource_params
      params.require(:subscriber_label).permit(:name, :color)
    end
  end
end
