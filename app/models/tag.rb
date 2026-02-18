class Tag < ApplicationRecord
  has_many :post_tags, dependent: :destroy
  has_many :posts, through: :post_tags

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/ }

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  def to_param
    slug
  end

  private

  def generate_slug
    self.slug = name.parameterize
  end
end
