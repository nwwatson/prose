module Authorization
  extend ActiveSupport::Concern

  private

  def require_admin
    unless current_user&.admin?
      redirect_to admin_root_path, alert: "You are not authorized to perform this action."
    end
  end

  def require_staff
    require_authentication unless signed_in?
  end
end
