class Newsletter < ApplicationRecord
  include Sendable
  include Templatable

  enum :status, { draft: 0, scheduled: 1, sending: 2, sent: 3 }

  belongs_to :user
  has_many :newsletter_deliveries, dependent: :destroy
  has_rich_text :body

  validates :title, presence: true

  scope :by_recency, -> { order(updated_at: :desc) }
  scope :search, ->(query) {
    where("title LIKE :q", q: "%#{sanitize_sql_like(query)}%")
  }
end
