class Comment < ApplicationRecord
  include Editable
  include Notifiable

  belongs_to :post
  belongs_to :identity
  belongs_to :parent_comment, class_name: "Comment", optional: true
  has_many :replies, class_name: "Comment", foreign_key: :parent_comment_id, dependent: :destroy
  has_many :approved_replies, -> { approved.order(:created_at) }, class_name: "Comment", foreign_key: :parent_comment_id

  validates :body, presence: true, length: { maximum: 5000 }
  validate :max_one_level_nesting

  scope :approved, -> { where(approved: true) }
  scope :top_level, -> { where(parent_comment_id: nil) }
  scope :pending_moderation, -> { where(approved: false) }
  scope :recent, -> { order(created_at: :desc) }

  after_create_commit :emit_created_webhook

  def rendered_body
    MarkdownRenderer.to_html(body)
  end

  def approve!
    return if approved?

    update!(approved: true)
    WebhookDispatcher.deliver("comment.approved", Webhooks::CommentSerializer.call(self))
  end

  private

  def emit_created_webhook
    WebhookDispatcher.deliver("comment.created", Webhooks::CommentSerializer.call(self))
  end

  def max_one_level_nesting
    if parent_comment&.parent_comment_id.present?
      errors.add(:parent_comment, "can only reply to top-level comments")
    end
  end
end
