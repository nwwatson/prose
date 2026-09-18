# Lets a subscriber choose which mailing lists they receive and how often they
# hear about new posts. Reached from
# the signed link in post emails (no sign-in needed) or, for a signed-in
# subscriber, directly.
class EmailPreferencesController < ApplicationController
  before_action :set_subscriber
  before_action :set_mailing_lists

  def show
  end

  def update
    if @subscriber.update(params.expect(subscriber: [ :email_frequency, selected_mailing_list_ids: [] ]))
      redirect_to email_preferences_path(token: params[:token].presence), notice: t("flash.email_preferences.updated")
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_subscriber
    @subscriber = params[:token].present? ? Subscriber.find_by_email_preferences_token(params[:token]) : current_subscriber
    redirect_to root_path, alert: t("flash.email_preferences.invalid_link") unless @subscriber
  end

  def set_mailing_lists
    @mailing_lists = MailingList.active.ordered
  end
end
