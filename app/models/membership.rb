class Membership < ApplicationRecord
  include StripeSyncable

  belongs_to :subscriber
  belongs_to :membership_tier

  enum :status, { active: 0, past_due: 1, canceled: 2, incomplete: 3, trialing: 4 }

  validates :status, presence: true

  scope :current, -> { where(status: [ :active, :trialing ]) }
  scope :canceled_since, ->(time) { canceled.where("canceled_at >= ?", time) }
  scope :by_recency, -> { order(created_at: :desc) }

  def self.grant_complimentary!(subscriber:, membership_tier:)
    create!(
      subscriber: subscriber,
      membership_tier: membership_tier,
      status: :active,
      current_period_start: Time.current,
      current_period_end: 100.years.from_now
    )
  end

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
