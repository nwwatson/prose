module Post::Publishable
  extend ActiveSupport::Concern
  include Publishable

  included do
    publishes_at :published_at

    scope :live, -> { where(status: [ :published, :scheduled ], published_at: ..Time.current) }
    scope :ready_to_publish, -> { scheduled.where(published_at: ..Time.current) }
  end

  # Status-transition predicates for the last save. Post::Notifiable,
  # Post::Webhookable and Post::Federatable all react to these from
  # `after_commit on: [:create, :update]`, so a post created already published
  # (the admin editor permits `status` on create) behaves exactly like a draft
  # being published. On create, the "before" status is the column default
  # (draft), so creating a draft is no transition at all.

  def became_published?
    saved_change_to_status? && published?
  end

  def became_scheduled?
    saved_change_to_status? && scheduled?
  end

  def left_published?
    saved_change_to_status? && status_before_last_save == "published"
  end

  # A save of an already-published post that produced a new revision
  # (see Post::Revisable) without changing its status.
  def edited_while_published?
    !saved_change_to_status? && published? && revised?
  end
end
