module Comment::Notifiable
  extend ActiveSupport::Concern

  # The unsubscribe link in reply emails carries this token. Links are already
  # sitting in inboxes: changing the verifier name or shortening the expiry
  # would break them.
  NOTIFICATION_TOKEN_EXPIRY = 30.days

  included do
    after_create_commit :notify_parent_comment_author
  end

  class_methods do
    def find_by_notification_token(token)
      find_by(id: notification_verifier.verified(token))
    end

    def notification_verifier
      Rails.application.message_verifier("comment_notification")
    end
  end

  # Identifies this comment as the one whose author stops reply emails.
  def notification_token
    self.class.notification_verifier.generate(id, expires_in: NOTIFICATION_TOKEN_EXPIRY)
  end

  # Whether the author of the parent comment should be emailed about this reply.
  def reply_notifiable?
    parent = parent_comment
    return false unless parent&.notify_on_reply?
    return false if parent.deleted? || parent.identity_id == identity_id

    parent.identity.subscriber&.confirmed_at? || false
  end

  private

  def notify_parent_comment_author
    CommentReplyNotificationJob.perform_later(self) if reply_notifiable?
  end
end
