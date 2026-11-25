class SendPostNotificationsJob < ApplicationJob
  queue_as :default

  BATCH_SIZE = 500

  def perform(post_id)
    post = Post.find(post_id)
    post.notification_recipients.email_immediate.in_batches(of: BATCH_SIZE) do |batch|
      ActionMailer.deliver_all_later(batch.map { |subscriber| PostNotificationMailer.new_post(subscriber, post) })
    end
  end
end
