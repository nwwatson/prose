class UnsubscribesController < ApplicationController
  before_action :set_subscriber_from_token

  def show
  end

  def create
    @subscriber.unsubscribe!
    render :create
  end

  private

  def set_subscriber_from_token
    @subscriber = Subscriber.find_by_unsubscribe_token(params[:token])
    redirect_to root_path, alert: t("flash.unsubscribes.invalid_link") unless @subscriber
  end
end
