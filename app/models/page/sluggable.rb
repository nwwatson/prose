module Page::Sluggable
  extend ActiveSupport::Concern

  included do
    validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/, message: "must be URL-safe (lowercase letters, numbers, hyphens)" }

    before_validation :generate_slug, if: -> { slug.blank? && title.present? }
  end

  private

  def generate_slug
    base_slug = title.parameterize
    self.slug = base_slug

    counter = 1
    while Page.where.not(id: id).exists?(slug: self.slug)
      self.slug = "#{base_slug}-#{counter}"
      counter += 1
    end
  end
end
