module Sluggable
  extend ActiveSupport::Concern

  SLUG_FORMAT = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/

  class_methods do
    # Configures slug generation from `attribute` on before_validation.
    # uniquify: append -1, -2, ... to disambiguate duplicate slugs (default true).
    # message: custom format validation error message.
    def slugged_from(attribute, uniquify: true, message: nil)
      format_options = { with: Sluggable::SLUG_FORMAT }
      format_options[:message] = message if message

      validates :slug, presence: true, uniqueness: true, format: format_options

      class_attribute :sluggable_source_attribute, instance_writer: false, default: attribute
      class_attribute :sluggable_uniquify, instance_writer: false, default: uniquify

      before_validation :generate_slug, if: -> { slug.blank? && send(attribute).present? }
    end
  end

  private

  def generate_slug
    base_slug = send(sluggable_source_attribute).parameterize
    self.slug = base_slug

    return unless sluggable_uniquify

    counter = 1
    while self.class.where.not(id: id).exists?(slug: slug)
      self.slug = "#{base_slug}-#{counter}"
      counter += 1
    end
  end
end
