module IdentityAuthentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_identity, :identity_signed_in?
    before_action :resume_user_session_if_present
  end

  private

  def current_identity
    Current.identity ||= Current.user&.identity || current_subscriber&.identity
  end

  def identity_signed_in?
    current_identity.present?
  end

  def require_identity
    redirect_to root_path, alert: t("flash.identity_authentication.sign_in_required") unless identity_signed_in?
  end

  def resume_user_session_if_present
    return if Current.user

    session_record = find_user_session_from_cookie
    return unless session_record

    if session_record.expired?
      session_record.destroy
      cookies.delete(:session_token)
      return
    end

    Current.session = session_record
    Current.user = session_record.user
  end

  def find_user_session_from_cookie
    token = cookies.signed[:session_token]
    return nil unless token

    Session.active.includes(:user).find_by(token: token)
  end
end
