module Subscriber::Billable
  extend ActiveSupport::Concern

  included do
    has_many :memberships, dependent: :destroy
  end

  def active_membership
    memberships.current.order(created_at: :desc).first
  end

  def paid_member?
    active_membership.present?
  end

  def free_member?
    confirmed? && !paid_member?
  end

  def stripe_customer_id
    memberships.where.not(stripe_customer_id: nil).order(created_at: :desc).pick(:stripe_customer_id)
  end
end
