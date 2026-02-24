class SubscriberSessionsController < ApplicationController
  def show
    subscriber = Subscriber.find_by(auth_token: params[:token])

    if subscriber&.consume_auth_token!(params[:token])
      cookies.signed.permanent[:subscriber_id] = { value: subscriber.id, httponly: true, same_site: :lax }
      Current.subscriber = subscriber
      redirect_to root_path, notice: t("flash.subscriber_sessions.signed_in")
    else
      redirect_to root_path, alert: t("flash.subscriber_sessions.link_expired")
    end
  end

  def destroy
    cookies.delete(:subscriber_id)
    Current.subscriber = nil
    redirect_to root_path, notice: t("flash.subscriber_sessions.signed_out")
  end
end
