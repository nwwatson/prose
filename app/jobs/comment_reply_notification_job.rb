class CommentReplyNotificationJob < ApplicationJob
  queue_as :default

  # Checked again here: the parent comment or its preferences may have changed
  # since the reply was queued.
  def perform(comment)
    CommentMailer.reply_notification(comment).deliver_now if comment.reply_notifiable?
  end
end
