class PostNotificationMailer < ApplicationMailer
  def new_post(subscriber, post)
    @subscriber = subscriber
    @post = post
    @unsubscribe_url = generate_unsubscribe_url(subscriber)
    load_email_branding

    set_list_unsubscribe_headers(@unsubscribe_url)

    mail(to: subscriber.email, subject: t("post_notification_mailer.new_post.subject", title: post.title))
  end
end
