class Category < ApplicationRecord
  include Sluggable

  has_many :posts, dependent: :nullify

  validates :name, presence: true, uniqueness: true

  slugged_from :name, uniquify: false

  scope :ordered, -> { order(:position) }

  def self.post_counts
    Post.where.not(category_id: nil).group(:category_id).count
  end

  def to_param
    slug
  end
end
