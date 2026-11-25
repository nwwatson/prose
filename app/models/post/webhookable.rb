# Fires post.* webhook events from status transitions (Post::Publishable).
#
# - post.published: the post became published (including created as published)
# - post.unpublished: the post left published, to draft or to scheduled
# - post.scheduled: the post became scheduled; published → scheduled sends
#   post.unpublished first, so receivers take the post down
#
# A scheduled post reverted to draft was never public, so it fires nothing.
module Post::Webhookable
  extend ActiveSupport::Concern

  included do
    after_commit :emit_status_webhooks, on: [ :create, :update ], if: :saved_change_to_status?
    # Only published posts emit post.updated/post.deleted, so draft titles and
    # slugs never reach third-party endpoints before the post goes live.
    # post.updated is coalesced: see Post::Revisable.
    after_commit :enqueue_updated_webhook, on: [ :create, :update ], if: :edited_while_published?
    after_destroy_commit :emit_deleted_webhook, if: :published?
  end

  private

  def emit_status_webhooks
    status_transition_events.each do |event|
      WebhookDispatcher.deliver(event) { Webhooks::PostSerializer.call(self) }
    end
  end

  def enqueue_updated_webhook
    PostUpdatedWebhookJob.set(wait: Post::Revisable::UPDATE_DELAY).perform_later(id, revised_at.to_f)
  end

  def emit_deleted_webhook
    WebhookDispatcher.deliver("post.deleted") { Webhooks::PostSerializer.call(self) }
  end

  def status_transition_events
    events = []
    events << "post.published" if became_published?
    events << "post.unpublished" if left_published?
    events << "post.scheduled" if became_scheduled?
    events
  end
end
