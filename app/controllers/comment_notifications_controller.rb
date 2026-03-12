class CommentNotificationsController < ApplicationController
  def destroy
    comment_id = Rails.application.message_verifier("comment_notification").verify(params[:token])
    comment = Comment.find(comment_id)
    comment.update!(notify_on_reply: false)
    redirect_to post_path(comment.post, slug: comment.post.slug), notice: t("flash.comment_notifications.unsubscribed")
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to root_path, alert: t("flash.comment_notifications.invalid_link")
  end
end
