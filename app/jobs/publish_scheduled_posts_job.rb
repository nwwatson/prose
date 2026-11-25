class PublishScheduledPostsJob < ApplicationJob
  queue_as :default

  def perform
    Post.ready_to_publish.find_each do |post|
      post.publish!
    rescue => e
      # One bad record must not block the others; it is retried on the next run.
      Rails.logger.error("[Scheduled Publishing] Failed to publish post #{post.id}: #{e.message}")
      Rails.error.report(e, handled: true, context: { post_id: post.id })
    end
  end
end
