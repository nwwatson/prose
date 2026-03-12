module Comment::Notifiable
  extend ActiveSupport::Concern

  included do
    after_create_commit :notify_parent_comment_author
  end

  private

  def notify_parent_comment_author
    return unless parent_comment&.notify_on_reply?
    return if parent_comment.deleted?
    return if parent_comment.identity_id == identity_id

    CommentReplyNotificationJob.perform_later(self)
  end
end
