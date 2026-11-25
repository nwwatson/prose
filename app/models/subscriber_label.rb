class SubscriberLabel < ApplicationRecord
  has_many :subscriber_labelings, dependent: :delete_all
  has_many :subscribers, through: :subscriber_labelings

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :color, presence: true, hex_color: { message: "must be a valid hex color (e.g. #6B7280)" }

  scope :ordered, -> { order(:name) }

  def self.subscriber_counts
    SubscriberLabeling.group(:subscriber_label_id).count
  end
end
