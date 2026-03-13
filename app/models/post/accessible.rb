module Post::Accessible
  extend ActiveSupport::Concern

  included do
    enum :visibility, { public: 0, members_only: 1, paid_only: 2 }, prefix: :visibility
  end

  def accessible_by?(subscriber)
    return true if visibility_public?
    return false if subscriber.blank?
    return true if subscriber.confirmed? && visibility_members_only?
    return subscriber.paid_member? if visibility_paid_only?

    false
  end

  def requires_membership?
    !visibility_public?
  end

  def requires_paid_membership?
    visibility_paid_only?
  end
end
