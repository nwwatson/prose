class Page < ApplicationRecord
  include Sluggable
  include Publishable
  include Navigable

  enum :status, { draft: 0, published: 1 }

  belongs_to :user
  has_rich_text :content

  validates :title, presence: true
  validates :meta_description, length: { maximum: 160 }, allow_blank: true

  RESERVED_SLUGS = %w[
    admin posts authors categories tags subscriptions feed sitemap robots up mcp
    subscriber_session handle handle_availability unsubscribe webhooks
  ].freeze

  validates :slug, exclusion: { in: RESERVED_SLUGS, message: "is reserved" }

  def to_param
    slug
  end

  def seo_description
    meta_description.presence || content&.to_plain_text&.truncate(155)
  end
end
