module Admin
  class SegmentsController < BaseController
    before_action :set_segment, only: [ :show, :edit, :update, :destroy, :count ]
    before_action :load_labels, only: %i[new create edit update]

    def index
      @segments = Segment.order(:name)
    end

    def show
      @subscribers = @segment.resolve.includes(:identity, :subscriber_labels).order(created_at: :desc)
    end

    def new
      @segment = Segment.new
    end

    def create
      @segment = Segment.new(segment_params)

      if @segment.save
        redirect_to admin_segments_path, notice: t("flash.admin.segments.created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @segment.update(segment_params)
        redirect_to admin_segments_path, notice: t("flash.admin.segments.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @segment.destroy
      redirect_to admin_segments_path, notice: t("flash.admin.segments.deleted")
    end

    def count
      render partial: "count", locals: { count: @segment.subscriber_count }
    end

    private

    def set_segment
      @segment = Segment.find(params[:id])
    end

    def load_labels
      @labels = SubscriberLabel.ordered
    end

    def segment_params
      params.require(:segment).permit(:name, :description, :engagement, :subscribed_after, :subscribed_before, :label_mode, label_ids: [])
    end
  end
end
