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
    subscriber_id = Rails.application.message_verifier("unsubscribe").verify(params[:token])
    @subscriber = Subscriber.find(subscriber_id)
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to root_path, alert: t("flash.unsubscribes.invalid_link")
  end
end
