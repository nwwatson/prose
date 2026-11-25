class CommentMailer < ApplicationMailer
  def reply_notification(comment)
    @comment = comment
    @parent_comment = comment.parent_comment
    @post = comment.post
    @replier_name = comment.identity.handle || comment.identity.name
    @unsubscribe_url = comment_notification_url(token: @parent_comment.notification_token)

    load_email_branding

    mail(
      to: @parent_comment.identity.subscriber&.email,
      subject: t("comment_mailer.reply_notification.subject", site_name: @site_name)
    )
  end
end
