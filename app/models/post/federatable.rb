# Mirrors a post's lifecycle to fediverse followers: publishing sends a Create,
# editing a published post sends an Update, and unpublishing or deleting it
# sends a Delete. Like Post::Webhookable, this lives on the model so the admin
# UI, MCP tools, REST API, and scheduled publishing all federate the same way.
module Post::Federatable
  extend ActiveSupport::Concern

  included do
    has_many :fediverse_likes, dependent: :destroy

    after_update_commit :federate_status_change, if: -> { saved_change_to_status? && federation_enabled? }
    after_update_commit :federate_update, if: -> { !saved_change_to_status? && published? && revised? && federation_enabled? }
    after_destroy_commit :federate_delete, if: -> { published? && federation_enabled? }
  end

  private

  def federate_status_change
    if published?
      FederatePostJob.perform_later("create", id, ActivityPub::Urls.post_url(self))
    elsif status_before_last_save == "published"
      federate_delete
    end
  end

  # Coalesced so followers get one Update per burst of edits (Post::Revisable).
  def federate_update
    FederatePostJob.set(wait: Post::Revisable::UPDATE_DELAY).perform_later("update", id, ActivityPub::Urls.post_url(self), revised_at.to_f)
  end

  def federate_delete
    FederatePostJob.perform_later("delete", id, ActivityPub::Urls.post_url(self))
  end

  def federation_enabled?
    SiteSetting.current.activitypub_enabled?
  end
end
