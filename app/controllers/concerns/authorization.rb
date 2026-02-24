module Authorization
  extend ActiveSupport::Concern

  private

  def require_admin
    unless current_user&.admin?
      redirect_to admin_root_path, alert: t("flash.authorization.not_authorized")
    end
  end

  def require_staff
    require_authentication unless signed_in?
  end
end
