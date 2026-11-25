# Stamps `revised_at` whenever a save changes something readers or
# integrations see, as opposed to settings-only saves (featured, show_toc,
# category) or counter bumps, which still move `updated_at`.
#
# Autosave can save a published post every few seconds while it's being
# edited, so Post::Webhookable and Post::Federatable send their "updated"
# notifications from a job delayed by UPDATE_DELAY that carries `revised_at`.
# A job whose revision has been superseded skips itself, so each burst of
# edits produces exactly one notification, describing the final state.
module Post::Revisable
  extend ActiveSupport::Concern

  UPDATE_DELAY = 2.minutes
  REVISED_ATTRIBUTES = %w[title subtitle slug body_plain visibility published_at meta_description].freeze

  included do
    # Declared after Post::Searchable's callback, so a content change has
    # already been copied into `body_plain` when this runs.
    before_save :stamp_revision, if: -> { new_record? || REVISED_ATTRIBUTES.any? { |attr| will_save_change_to_attribute?(attr) } }
  end

  # Whether the last save produced a new revision.
  def revised?
    saved_change_to_revised_at?
  end

  # Whether the post has been revised again since `revision` (a `revised_at`
  # captured when a delayed job was enqueued). Float timestamps survive job
  # serialization; the millisecond slack absorbs rounding.
  def revised_since?(revision)
    revision.present? && revised_at.to_f > revision.to_f + 0.001
  end

  private

  def stamp_revision
    self.revised_at = Time.current
  end
end
