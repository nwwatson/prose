class SubscriberLabel < ApplicationRecord
  has_many :subscriber_labelings, dependent: :destroy
  has_many :subscribers, through: :subscriber_labelings

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :color, presence: true, format: { with: /\A#[0-9a-fA-F]{6}\z/, message: "must be a valid hex color (e.g. #6B7280)" }

  scope :ordered, -> { order(:name) }
end
