module Admin
  class MailingListsController < BaseController
    before_action :set_mailing_list, only: [ :edit, :update, :destroy ]

    def index
      @mailing_lists = MailingList.ordered
      @subscriber_counts = MailingList.subscriber_counts
    end

    def new
      @mailing_list = MailingList.new
    end

    def create
      @mailing_list = MailingList.new(mailing_list_params)

      if @mailing_list.save
        redirect_to admin_mailing_lists_path, notice: t("flash.admin.mailing_lists.created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @mailing_list.update(mailing_list_params)
        redirect_to admin_mailing_lists_path, notice: t("flash.admin.mailing_lists.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @mailing_list.destroy
      redirect_to admin_mailing_lists_path, notice: t("flash.admin.mailing_lists.deleted")
    end

    private

    def set_mailing_list
      @mailing_list = MailingList.find(params[:id])
    end

    def mailing_list_params
      params.require(:mailing_list).permit(:name, :description, :frequency, :active, :subscribe_by_default)
    end
  end
end
