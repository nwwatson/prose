class Comment < ApplicationRecord
  belongs_to :post
  belongs_to :identity
  belongs_to :parent_comment, class_name: "Comment", optional: true
  has_many :replies, class_name: "Comment", foreign_key: :parent_comment_id, dependent: :destroy

  validates :body, presence: true, length: { maximum: 5000 }
  validate :max_one_level_nesting

  scope :approved, -> { where(approved: true) }
  scope :top_level, -> { where(parent_comment_id: nil) }
  scope :pending_moderation, -> { where(approved: false) }
  scope :recent, -> { order(created_at: :desc) }

  private

  def max_one_level_nesting
    if parent_comment&.parent_comment_id.present?
      errors.add(:parent_comment, "can only reply to top-level comments")
    end
  end
end
