module IdentityAuthentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_identity, :identity_signed_in?
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
end
