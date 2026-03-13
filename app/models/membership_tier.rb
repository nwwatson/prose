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

  def price_in_dollars
    price_cents / 100.0
  end

  def formatted_price
    symbol = case currency
    when "eur" then "\u20AC"
    when "gbp" then "\u00A3"
    else "$"
    end
    "#{symbol}#{format("%.2f", price_in_dollars)}"
  end

  def interval_label
    month? ? "/mo" : "/yr"
  end
end
