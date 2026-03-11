module Admin
  class SubscriberLabelingsController < BaseController
    before_action :set_subscriber

    def create
      @label = SubscriberLabel.find(params[:subscriber_label_id])
      @labeling = @subscriber.subscriber_labelings.build(subscriber_label: @label)

      if @labeling.save
        respond_to do |format|
          format.turbo_stream { render turbo_stream: turbo_stream.append("subscriber_labels", partial: "admin/subscriber_labelings/labeling", locals: { labeling: @labeling, subscriber: @subscriber }) }
          format.html { redirect_to admin_subscriber_path(@subscriber) }
        end
      else
        redirect_to admin_subscriber_path(@subscriber), alert: t("flash.admin.subscriber_labelings.already_assigned")
      end
    end

    def destroy
      @labeling = @subscriber.subscriber_labelings.find(params[:id])
      @labeling.destroy

      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.remove(@labeling) }
        format.html { redirect_to admin_subscriber_path(@subscriber) }
      end
    end

    private

    def set_subscriber
      @subscriber = Subscriber.find(params[:subscriber_id])
    end
  end
end
