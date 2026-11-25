class CommentNotificationsController < ApplicationController
  def destroy
    comment = Comment.find_by_notification_token(params[:token])
    return redirect_to(root_path, alert: t("flash.comment_notifications.invalid_link")) unless comment

    comment.update!(notify_on_reply: false)
    redirect_to post_path(slug: comment.post.slug), notice: t("flash.comment_notifications.unsubscribed")
  end
end
