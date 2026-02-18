class PostNotificationMailer < ApplicationMailer
  def new_post(subscriber, post)
    @subscriber = subscriber
    @post = post
    mail(to: subscriber.email, subject: "New post: #{post.title}")
  end
end
