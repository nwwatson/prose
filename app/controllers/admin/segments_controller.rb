module Admin
  class SegmentsController < BaseController
    include Admin::CrudResource
    crud_resource Segment, member_actions: %i[show count]
    before_action :load_labels, only: %i[new create edit update]

    def index
      @segments = paginate(Segment.order(:name, :id))
    end

    def show
      @subscribers = paginate(@segment.resolve.includes(:subscriber_labels).order(created_at: :desc, id: :desc))
    end

    def count
      render partial: "count", locals: { count: @segment.subscriber_count }
    end

    private

    def load_labels
      @labels = SubscriberLabel.ordered
    end

    def resource_params
      params.require(:segment).permit(:name, :description, :engagement, :subscribed_after, :subscribed_before, :label_mode, label_ids: [])
    end
  end
end
