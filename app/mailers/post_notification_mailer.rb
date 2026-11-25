class PostNotificationMailer < ApplicationMailer
  def new_post(subscriber, post)
    @subscriber = subscriber
    @post = post
    prepare_subscriber_links(subscriber)
    load_email_branding

    mail(to: subscriber.email, subject: t("post_notification_mailer.new_post.subject", title: post.title))
  end
end
