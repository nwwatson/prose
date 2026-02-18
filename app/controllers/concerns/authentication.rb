module Authentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_user, :signed_in?
  end

  private

  def current_user
    Current.user
  end

  def signed_in?
    current_user.present?
  end

  def require_authentication
    resume_session || redirect_to_login
  end

  def resume_session
    session_record = find_session_from_cookie
    return false unless session_record

    if session_record.expired?
      session_record.destroy
      cookies.delete(:session_token)
      return false
    end

    Current.session = session_record
    Current.user = session_record.user
  end

  def start_session(user, ip_address:, user_agent:)
    session_record = user.create_session!(ip_address: ip_address, user_agent: user_agent)
    Current.session = session_record
    Current.user = user
    cookies.signed.permanent[:session_token] = { value: session_record.token, httponly: true, same_site: :lax }
    session_record
  end

  def end_session
    Current.session&.destroy
    Current.session = nil
    Current.user = nil
    cookies.delete(:session_token)
  end

  def find_session_from_cookie
    token = cookies.signed[:session_token]
    return nil unless token

    Session.active.includes(:user).find_by(token: token)
  end

  def redirect_to_login
    if User.none?
      redirect_to new_admin_setup_path
    else
      redirect_to new_admin_session_path, alert: "Please sign in to continue."
    end
  end
end
