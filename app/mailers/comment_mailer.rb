class CommentMailer < ApplicationMailer
  def reply_notification(comment)
    @comment = comment
    @parent_comment = comment.parent_comment
    @post = comment.post
    @replier_name = comment.identity.handle || comment.identity.name
    @unsubscribe_url = generate_comment_unsubscribe_url(@parent_comment)

    load_email_branding

    mail(
      to: @parent_comment.identity.subscriber&.email,
      subject: t("comment_mailer.reply_notification.subject", site_name: @site_name)
    )
  end

  private

  def generate_comment_unsubscribe_url(comment)
    token = Rails.application.message_verifier("comment_notification").generate(
      comment.id,
      expires_in: 30.days
    )
    comment_notification_url(token: token)
  end
end
