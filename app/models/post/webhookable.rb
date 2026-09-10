module Post::Webhookable
  extend ActiveSupport::Concern

  included do
    after_update_commit :emit_status_webhook, if: :saved_change_to_status?
    after_update_commit :emit_updated_webhook, unless: :saved_change_to_status?
    after_destroy_commit :emit_deleted_webhook
  end

  private

  def emit_status_webhook
    event = status_transition_event
    WebhookDispatcher.deliver(event, Webhooks::PostSerializer.call(self)) if event
  end

  def emit_updated_webhook
    WebhookDispatcher.deliver("post.updated", Webhooks::PostSerializer.call(self))
  end

  def emit_deleted_webhook
    WebhookDispatcher.deliver("post.deleted", Webhooks::PostSerializer.call(self))
  end

  def status_transition_event
    case status
    when "published" then "post.published"
    when "scheduled" then "post.scheduled"
    when "draft" then "post.unpublished"
    end
  end
end
