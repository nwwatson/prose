class SubscriptionsController < ApplicationController
  def create
    @subscriber = Subscriber.subscribe_or_sign_in!(email: params[:email], source_post_id: params[:source_post_id])

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to root_path, notice: t("flash.subscriptions.check_email") }
    end
  rescue ActiveRecord::RecordInvalid
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("subscription_form", partial: "subscriptions/form", locals: { error: t("flash.subscriptions.invalid_email") }) }
      format.html { redirect_to root_path, alert: t("flash.subscriptions.invalid_email") }
    end
  end
end
