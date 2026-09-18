class SendPostNotificationsJob < ApplicationJob
  queue_as :default

  def perform(post_id)
    post = Post.find(post_id)
    post.notification_recipients.email_immediate.find_each do |subscriber|
      PostNotificationMailer.new_post(subscriber, post).deliver_later
    end
  end
end
