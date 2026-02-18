class PublishScheduledPostsJob < ApplicationJob
  queue_as :default

  def perform
    Post.ready_to_publish.find_each do |post|
      post.publish!
    end
  end
end
