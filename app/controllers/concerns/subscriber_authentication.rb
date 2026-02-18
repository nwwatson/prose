module SubscriberAuthentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_subscriber, :subscriber_signed_in?
    before_action :resume_subscriber_session
  end

  private

  def current_subscriber
    Current.subscriber
  end

  def subscriber_signed_in?
    current_subscriber.present?
  end

  def resume_subscriber_session
    subscriber_id = cookies.signed[:subscriber_id]
    return unless subscriber_id

    Current.subscriber = Subscriber.confirmed.find_by(id: subscriber_id)
    unless Current.subscriber
      cookies.delete(:subscriber_id)
    end
  end
end
