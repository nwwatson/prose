class Tag < ApplicationRecord
  include Sluggable

  has_many :post_tags, dependent: :destroy
  has_many :posts, through: :post_tags

  validates :name, presence: true, uniqueness: true

  slugged_from :name, uniquify: false

  def self.post_counts
    PostTag.group(:tag_id).count
  end

  def to_param
    slug
  end
end
