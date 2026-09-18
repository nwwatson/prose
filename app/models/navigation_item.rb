class NavigationItem < ApplicationRecord
  include Cacheable
  include SocialPlatform

  enum :location, { header: 0, footer: 1, social: 2 }, validate: true

  # Internal paths ("/about", "/posts?page=2", "/#top"), http(s) URLs, and mailto: links.
  # Protocol-relative ("//host") and script URLs are rejected.
  INTERNAL_PATH = %r{\A/(?!/)\S*\z}
  EXTERNAL_URL = URI::DEFAULT_PARSER.make_regexp(%w[http https])
  MAILTO = /\Amailto:[^\s@]+@[^\s@]+\z/i

  normalizes :label, with: ->(label) { label.strip }
  normalizes :url, with: ->(url) { url.strip }

  validates :label, presence: true, length: { maximum: 50 }
  validates :url, presence: true, length: { maximum: 2048 }
  validate :url_must_be_linkable

  before_save :append_to_location, if: -> { new_record? || will_save_change_to_location? }

  scope :ordered, -> { order(:position, :id) }

  # Rewrites positions within one location to match the given id order.
  # Ids that don't belong to the location are ignored.
  def self.reposition!(location, ids)
    items = where(location: location).index_by(&:id)
    ordered_ids = ids.map(&:to_i).select { |id| items.key?(id) }
    ordered_ids += items.keys - ordered_ids

    transaction do
      ordered_ids.each_with_index do |id, index|
        items[id].update_columns(position: index, updated_at: Time.current) if items[id].position != index
      end
    end
    expire_navigation_cache
  end

  def move(direction)
    siblings = self.class.where(location: location).ordered.ids
    index = siblings.index(id)
    target = direction.to_s == "up" ? index - 1 : index + 1
    return if target.negative? || target >= siblings.size

    siblings[index], siblings[target] = siblings[target], siblings[index]
    self.class.reposition!(location, siblings)
  end

  def external?
    url.match?(/\A(https?|mailto):/i)
  end

  private

  def url_must_be_linkable
    return if url.blank?

    if social?
      errors.add(:url, :navigation_social_url) unless url.match?(/\A#{EXTERNAL_URL}\z/)
    elsif !(url.match?(INTERNAL_PATH) || url.match?(/\A#{EXTERNAL_URL}\z/) || url.match?(MAILTO))
      errors.add(:url, :navigation_link)
    end
  end

  def append_to_location
    self.position = (self.class.where(location: location).maximum(:position) || -1) + 1
  end
end
