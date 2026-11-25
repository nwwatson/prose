module Admin
  class SubscribersController < BaseController
    def index
      subscribers = Subscriber.includes(:identity, :subscriber_labels)
        .search(params[:search])
        .with_label(params[:label])
        .order(created_at: :desc, id: :desc)

      @subscribers = paginate(subscribers)
      @labels = SubscriberLabel.ordered
      @confirmed_subscribers_count = Subscriber.confirmed.count
      @total_subscribers_count = Subscriber.count
    end

    def show
      @subscriber = Subscriber.includes(:identity, :subscriber_labels).find(params[:id])
      @available_labels = SubscriberLabel.ordered - @subscriber.subscriber_labels
      @available_membership_tiers = MembershipTier.active.ordered
    end
  end
end
