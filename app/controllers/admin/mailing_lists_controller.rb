module Admin
  class MailingListsController < BaseController
    include Admin::CrudResource
    crud_resource MailingList

    def index
      @mailing_lists = MailingList.ordered
      @subscriber_counts = MailingList.subscriber_counts
    end

    private

    def resource_params
      params.require(:mailing_list).permit(:name, :description, :frequency, :active, :subscribe_by_default)
    end
  end
end
