module Admin
  class SubscriberLabelsController < BaseController
    before_action :set_label, only: [ :edit, :update, :destroy ]

    def index
      @labels = SubscriberLabel.ordered
    end

    def new
      @label = SubscriberLabel.new
    end

    def create
      @label = SubscriberLabel.new(label_params)

      if @label.save
        redirect_to admin_subscriber_labels_path, notice: t("flash.admin.subscriber_labels.created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @label.update(label_params)
        redirect_to admin_subscriber_labels_path, notice: t("flash.admin.subscriber_labels.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @label.destroy
      redirect_to admin_subscriber_labels_path, notice: t("flash.admin.subscriber_labels.deleted")
    end

    private

    def set_label
      @label = SubscriberLabel.find(params[:id])
    end

    def label_params
      params.require(:subscriber_label).permit(:name, :color)
    end
  end
end
