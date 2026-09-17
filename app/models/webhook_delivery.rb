class WebhookDelivery < ApplicationRecord
  belongs_to :webhook

  validates :event, presence: true
  validates :attempted_at, presence: true

  scope :recent, -> { order(attempted_at: :desc) }
end
