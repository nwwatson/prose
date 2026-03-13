class Membership < ApplicationRecord
  belongs_to :subscriber
  belongs_to :membership_tier

  enum :status, { active: 0, past_due: 1, canceled: 2, incomplete: 3, trialing: 4 }

  validates :status, presence: true

  scope :current, -> { where(status: [ :active, :trialing ]) }
  scope :by_recency, -> { order(created_at: :desc) }

  def cancel!
    if stripe_subscription_id.present? && PaymentService.configured?
      PaymentService.provider.cancel_subscription(stripe_subscription_id)
    end
    update!(status: :canceled, canceled_at: Time.current)
  end

  def complimentary?
    stripe_subscription_id.blank?
  end
end
