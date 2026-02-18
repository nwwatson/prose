class SendPostNotificationsJob < ApplicationJob
  queue_as :default

  def perform(post_id)
    post = Post.find(post_id)
    Subscriber.confirmed.find_each do |subscriber|
      PostNotificationMailer.new_post(subscriber, post).deliver_later
    end
  end
end
