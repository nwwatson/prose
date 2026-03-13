module MembershipAccess
  extend ActiveSupport::Concern

  private

  def can_view_post?(post)
    return true if post.visibility_public?
    return true if defined?(current_user) && current_user.present?
    return false if current_subscriber.blank?

    post.accessible_by?(current_subscriber)
  end

  def payments_configured?
    PaymentService.configured?
  end
end
