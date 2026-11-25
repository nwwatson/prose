# Builds a post's Create/Update/Delete activity and fans it out to one
# DeliverActivityJob per follower inbox (shared inboxes are deduplicated).
class FederatePostJob < ApplicationJob
  queue_as :default

  # `revision` (the post's `revised_at`) is set for coalesced "update" jobs: if
  # the post has been revised again since this job was enqueued, a newer job
  # will send the latest version.
  def perform(action, post_id, post_url, revision = nil)
    return unless SiteSetting.current.activitypub_enabled?

    activity = build_activity(action, post_id, post_url, revision)
    return unless activity

    body = activity.to_json
    FediverseActor.follower_inboxes.each { |inbox| DeliverActivityJob.perform_later(inbox, body) }
  end

  private

  def build_activity(action, post_id, post_url, revision)
    return ActivityPub::Activities.delete(post_url) if action == "delete"

    post = Post.live.find_by(id: post_id)
    return unless post

    case action
    when "create" then ActivityPub::Activities.create(post)
    when "update" then ActivityPub::Activities.update(post) unless post.revised_since?(revision)
    end
  end
end
