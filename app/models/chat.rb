class Chat < ApplicationRecord
  acts_as_chat messages_foreign_key: :chat_id

  belongs_to :post
  belongs_to :user

  validates :conversation_type, presence: true, inclusion: { in: %w[chat proofread critique brainstorm seo social image] }

  scope :for_post_and_user, ->(post, user) { where(post: post, user: user) }

  def self.find_or_create_for(post:, user:, conversation_type: "chat")
    find_or_create_by!(post: post, user: user, conversation_type: conversation_type)
  end
end
