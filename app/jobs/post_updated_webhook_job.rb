# Sends the coalesced post.updated webhook for a burst of edits to a
# published post (see Post::Revisable). Enqueued with a delay by
# Post::Webhookable; skips itself when a later revision has its own job queued,
# or when the post is no longer live.
class PostUpdatedWebhookJob < ApplicationJob
  queue_as :default

  def perform(post_id, revision)
    post = Post.live.find_by(id: post_id)
    return if post.nil? || post.revised_since?(revision)

    WebhookDispatcher.deliver("post.updated") { Webhooks::PostSerializer.call(post) }
  end
end
