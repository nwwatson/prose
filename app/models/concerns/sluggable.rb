# frozen_string_literal: true

module Sluggable
  extend ActiveSupport::Concern

  included do
    before_validation :generate_slug, on: :create
    validates :slug, presence: true, uniqueness: { scope: slug_scope }
  end

  class_methods do
    def slug_scope
      nil # Override in model if needed
    end
  end

  def to_param
    slug
  end

  private

  def generate_slug
    return if slug.present?

    base_slug = slug_source.parameterize
    self.slug = base_slug

    counter = 1
    while self.class.exists?(slug: slug)
      self.slug = "#{base_slug}-#{counter}"
      counter += 1
    end
  end

  def slug_source
    title # Override in model if different
  end
end
