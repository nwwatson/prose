# frozen_string_literal: true

module Sluggable
  extend ActiveSupport::Concern

  included do
    before_validation :generate_slug, on: :create
    validates :slug, presence: true
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
    while slug_exists?(slug)
      self.slug = "#{base_slug}-#{counter}"
      counter += 1
    end
  end

  def slug_exists?(slug_to_check)
    scope_column = self.class.slug_scope || (respond_to?(:slug_scope) ? slug_scope : nil)
    if scope_column
      scope_value = send(scope_column)
      self.class.exists?(slug: slug_to_check, scope_column => scope_value)
    else
      self.class.exists?(slug: slug_to_check)
    end
  end

  def slug_source
    title # Override in model if different
  end
end
