class ReadingListItem < ApplicationRecord
  # Keeps the ids the layout embeds for signed-in readers (and any one import) bounded.
  MAX_ITEMS = 500

  belongs_to :identity
  belongs_to :post

  validates :post_id, uniqueness: { scope: :identity_id }
  validate :within_limit, on: :create

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  private

  def within_limit
    return unless identity && identity.reading_list_items.count >= MAX_ITEMS

    errors.add(:base, :reading_list_full, count: MAX_ITEMS)
  end
end
