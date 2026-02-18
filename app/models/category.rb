class Category < ApplicationRecord
  has_many :posts, dependent: :nullify

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/ }

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  scope :ordered, -> { order(:position) }

  def to_param
    slug
  end

  private

  def generate_slug
    self.slug = name.parameterize
  end
end
