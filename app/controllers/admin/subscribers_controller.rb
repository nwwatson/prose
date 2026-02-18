module Admin
  class SubscribersController < BaseController
    def index
      @subscribers = Subscriber.includes(:identity).order(created_at: :desc)

      if params[:search].present?
        search_term = "%#{Subscriber.sanitize_sql_like(params[:search])}%"
        @subscribers = @subscribers.left_joins(:identity)
          .where("subscribers.email LIKE ? OR identities.handle LIKE ?", search_term, search_term)
      end
    end

    def show
      @subscriber = Subscriber.includes(:identity).find(params[:id])
    end
  end
end
