module Admin
  class SubscribersController < BaseController
    def index
      @subscribers = Subscriber.includes(:identity, :subscriber_labels).order(created_at: :desc)

      if params[:search].present?
        search_term = "%#{Subscriber.sanitize_sql_like(params[:search])}%"
        @subscribers = @subscribers.left_joins(:identity)
          .where("subscribers.email LIKE ? OR identities.handle LIKE ?", search_term, search_term)
      end

      if params[:label].present?
        @subscribers = @subscribers.joins(:subscriber_labels).where(subscriber_labels: { id: params[:label] })
      end

      @labels = SubscriberLabel.ordered
    end

    def show
      @subscriber = Subscriber.includes(:identity, :subscriber_labels).find(params[:id])
      @available_labels = SubscriberLabel.ordered - @subscriber.subscriber_labels
    end
  end
end
