class PostNotificationMailer < ApplicationMailer
  def new_post(subscriber, post)
    @subscriber = subscriber
    @post = post
    mail(to: subscriber.email, subject: t("post_notification_mailer.new_post.subject", title: post.title))
  end
end
