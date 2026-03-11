module Admin
  class SegmentsController < BaseController
    before_action :set_segment, only: [ :show, :edit, :update, :destroy, :count ]

    def index
      @segments = Segment.order(:name)
    end

    def show
      @subscribers = @segment.resolve.includes(:identity, :subscriber_labels).order(created_at: :desc)
    end

    def new
      @segment = Segment.new
      @labels = SubscriberLabel.ordered
    end

    def create
      @segment = Segment.new(segment_params)

      if @segment.save
        redirect_to admin_segments_path, notice: t("flash.admin.segments.created")
      else
        @labels = SubscriberLabel.ordered
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @labels = SubscriberLabel.ordered
    end

    def update
      if @segment.update(segment_params)
        redirect_to admin_segments_path, notice: t("flash.admin.segments.updated")
      else
        @labels = SubscriberLabel.ordered
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

    def segment_params
      params.require(:segment).permit(:name, :description, :engagement, :subscribed_after, :subscribed_before, :label_mode, label_ids: []).then do |permitted|
        build_filter_criteria(permitted)
      end
    end

    def build_filter_criteria(permitted)
      criteria = {}

      label_ids = permitted.delete(:label_ids)&.reject(&:blank?)
      label_mode = permitted.delete(:label_mode)
      if label_ids.present?
        criteria[:labels] = { ids: label_ids.map(&:to_i), mode: label_mode.presence || "any_of" }
      end

      subscribed_after = permitted.delete(:subscribed_after)
      criteria[:subscribed_after] = subscribed_after if subscribed_after.present?

      subscribed_before = permitted.delete(:subscribed_before)
      criteria[:subscribed_before] = subscribed_before if subscribed_before.present?

      engagement = permitted.delete(:engagement)
      criteria[:engagement] = engagement if engagement.present?

      permitted[:filter_criteria] = criteria
      permitted
    end
  end
end
