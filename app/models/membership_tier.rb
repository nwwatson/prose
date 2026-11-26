class MembershipTier < ApplicationRecord
  include Syncable

  enum :interval, { month: 0, year: 1 }

  has_many :memberships, dependent: :restrict_with_error

  validates :name, presence: true
  validates :price_cents, presence: true, numericality: { greater_than: 0 }
  validates :currency, presence: true
  validates :interval, presence: true

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :price_cents) }

  def self.current_member_counts
    Membership.current.group(:membership_tier_id).count
  end

  def formatted_price
    Currency.format(price_cents, currency)
  end

  def interval_label
    month? ? "/mo" : "/yr"
  end
end
