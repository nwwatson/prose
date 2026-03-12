module Comment::Editable
  extend ActiveSupport::Concern

  EDIT_WINDOW = 15.minutes

  included do
    scope :visible, -> { where(deleted_at: nil) }
  end

  def editable_by?(identity)
    return false unless identity
    return false if deleted?

    self.identity_id == identity.id && within_edit_window?
  end

  def deletable_by?(identity)
    return false unless identity
    return false if deleted?

    self.identity_id == identity.id
  end

  def soft_delete!
    update!(deleted_at: Time.current, body: "[deleted]")
  end

  def deleted?
    deleted_at.present?
  end

  def edited?
    edited_at.present?
  end

  private

  def within_edit_window?
    created_at > EDIT_WINDOW.ago
  end
end
