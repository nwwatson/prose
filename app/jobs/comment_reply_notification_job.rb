class CommentReplyNotificationJob < ApplicationJob
  queue_as :default

  def perform(comment)
    return unless comment.parent_comment&.notify_on_reply?
    return if comment.parent_comment.deleted?
    return if comment.parent_comment.identity_id == comment.identity_id

    recipient = comment.parent_comment.identity.subscriber
    return unless recipient&.confirmed_at?

    CommentMailer.reply_notification(comment).deliver_later
  end
end
