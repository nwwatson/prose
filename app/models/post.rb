class Post < ApplicationRecord
  include Sluggable
  include Publishable
  include Searchable
  include Discoverable

  enum :status, { draft: 0, scheduled: 1, published: 2 }

  belongs_to :user
  belongs_to :category, optional: true
  has_many :post_tags, dependent: :destroy
  has_many :tags, through: :post_tags
  has_many :loves, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :post_views, dependent: :destroy
  has_many :attributed_subscribers, class_name: "Subscriber", foreign_key: :source_post_id, dependent: :nullify
  has_many :chats, dependent: :destroy
  has_rich_text :content
  has_one_attached :featured_image

  validates :title, presence: true
  validates :meta_description, length: { maximum: 160 }, allow_blank: true

  def to_param
    slug
  end

  def seo_description
    meta_description.presence || subtitle.presence || content&.to_plain_text&.truncate(155)
  end

  scope :featured, -> { where(featured: true) }
  scope :by_publication_date, -> { order(published_at: :desc) }

  before_save :calculate_reading_time

  private

  def calculate_reading_time
    text = body_plain.to_s
    words = text.split.size
    self.reading_time_minutes = [ (words / 238.0).ceil, 1 ].max
  end
end
