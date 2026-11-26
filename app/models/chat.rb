class Chat < ApplicationRecord
  acts_as_chat

  belongs_to :post
  belongs_to :user

  validates :conversation_type, presence: true, inclusion: { in: %w[chat proofread critique brainstorm seo social image] }

  # What the chat panel shows: no system or tool messages.
  def conversation_messages
    messages.where(role: %w[user assistant]).order(:created_at)
  end

  def self.find_or_create_for(post:, user:, conversation_type: "chat")
    find_or_create_by!(post: post, user: user, conversation_type: conversation_type)
  end
end
