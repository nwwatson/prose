class SubscriptionsController < ApplicationController
  def create
    @subscriber = Subscriber.find_or_initialize_by(email: params[:email])

    if @subscriber.new_record?
      @subscriber.save!
      @subscriber.generate_auth_token!
      SubscriberMailer.confirmation(@subscriber).deliver_later
    else
      @subscriber.generate_auth_token!
      SubscriberMailer.magic_link(@subscriber).deliver_later
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to root_path, notice: "Check your email for a sign-in link." }
    end
  rescue ActiveRecord::RecordInvalid
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("subscription_form", partial: "subscriptions/form", locals: { error: "Please enter a valid email address." }) }
      format.html { redirect_to root_path, alert: "Please enter a valid email address." }
    end
  end
end
