# Mirrors a post's lifecycle to fediverse followers: publishing sends a Create,
# editing a published post sends an Update, and unpublishing or deleting it
# sends a Delete. Like Post::Webhookable, this lives on the model so the admin
# UI, MCP tools, REST API, and scheduled publishing all federate the same way.
module Post::Federatable
  extend ActiveSupport::Concern

  included do
    has_many :fediverse_likes, dependent: :destroy

    # Transitions come from Post::Publishable, shared with Post::Webhookable
    # and Post::Notifiable, so a post created already published sends a Create.
    after_commit :federate_status_change, on: [ :create, :update ], if: -> { saved_change_to_status? && federation_enabled? }
    after_commit :federate_update, on: [ :create, :update ], if: -> { edited_while_published? && federation_enabled? }
    after_destroy_commit :federate_delete, if: -> { published? && federation_enabled? }
  end

  private

  def federate_status_change
    if became_published?
      FederatePostJob.perform_later("create", id, ActivityPub::Urls.post_url(self))
    elsif left_published?
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
