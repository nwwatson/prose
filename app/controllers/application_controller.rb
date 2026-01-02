class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :authenticate_user!

  protected

  def current_user
    @current_user ||= find_user_by_session || find_user_by_remember_token
  end

  def user_signed_in?
    current_user.present?
  end

  def authenticate_user!
    unless user_signed_in?
      redirect_to new_session_path, alert: "Please sign in to continue."
    end
  end

  def sign_in(user, remember_me: false)
    session[:user_id] = user.id
    user.generate_remember_token if remember_me
    user.track_sign_in!(request)
  end

  def sign_out
    current_user&.clear_remember_token
    session.delete(:user_id)
    cookies.delete(:remember_token)
    @current_user = nil
  end

  def skip_authentication
    @skip_authentication = true
  end

  def authentication_skipped?
    @skip_authentication == true
  end

  helper_method :current_user, :user_signed_in?

  private

  def find_user_by_session
    return unless session[:user_id]

    User.find_by(id: session[:user_id])
  end

  def find_user_by_remember_token
    return unless cookies[:remember_token]

    user = User.find_by(remember_token: cookies[:remember_token])
    return unless user

    session[:user_id] = user.id
    user
  end
end
