# frozen_string_literal: true

class Post < ApplicationRecord
  include Sluggable
  include Publishable

  belongs_to :publication

  has_rich_text :content
  has_one_attached :featured_image

  validates :slug, uniqueness: { scope: :publication_id }
  validates :title, presence: true, length: { maximum: 200 }
  validates :summary, length: { maximum: 500 }
  validates :meta_title, length: { maximum: 60 }
  validates :meta_description, length: { maximum: 160 }
  validates :reading_time, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :view_count, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :published, -> { where(status: "published") }
  scope :featured, -> { where(featured: true) }
  scope :pinned, -> { where(pinned: true) }
  scope :ordered_by_date, -> { order(published_at: :desc, created_at: :desc) }
  scope :recent, -> { limit(10) }

  before_save :calculate_reading_time, if: :content_changed?
  after_create_commit :broadcast_creation

  def slug_source
    title
  end

  def slug_scope
    publication_id
  end

  def excerpt(length = 150)
    return summary if summary.present?

    content.to_plain_text.truncate(length)
  end

  def word_count
    content.to_plain_text.split.length
  end

  def estimated_reading_time
    # Average reading speed: 200 words per minute
    [ 1, (word_count / 200.0).ceil ].max
  end

  def seo_title
    meta_title.presence || title
  end

  def seo_description
    meta_description.presence || excerpt(160)
  end

  def featured_image_url(variant = :medium)
    return unless featured_image.attached?

    case variant
    when :thumb
      featured_image.variant(resize_to_limit: [ 400, 400 ])
    when :medium
      featured_image.variant(resize_to_limit: [ 800, 600 ])
    when :large
      featured_image.variant(resize_to_limit: [ 1200, 900 ])
    when :og
      featured_image.variant(resize_to_fill: [ 1200, 630 ])
    else
      featured_image
    end
  end

  def increment_view_count!
    increment!(:view_count)
  end

  def toggle_featured!
    update!(featured: !featured?)
  end

  def toggle_pinned!
    update!(pinned: !pinned?)
  end

  private

  def calculate_reading_time
    self.reading_time = estimated_reading_time
  end

  def broadcast_creation
    # Placeholder for future Turbo Stream broadcasts
    # Will be implemented in Phase 3 (Email campaigns)
  end

  def content_changed?
    content&.changed? || false
  end

  class << self
    def slug_scope
      :publication_id
    end
  end
end
