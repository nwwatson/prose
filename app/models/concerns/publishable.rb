module Publishable
  extend ActiveSupport::Concern

  included do
    class_attribute :publishable_timestamp_column, default: :published_at
  end

  class_methods do
    def publishes_at(column = :published_at)
      self.publishable_timestamp_column = column

      scope :live, -> { where(status: :published).where(column => ..Time.current) }

      validates column, future: true, if: -> { try(:scheduled?) && public_send(:"#{column}_changed?") }
    end
  end

  def publish!
    update!(status: :published, publishable_timestamp_column => (public_send(publishable_timestamp_column) || Time.current))
  end

  def schedule!(time)
    update!(status: :scheduled, publishable_timestamp_column => time)
  end

  def revert_to_draft!
    update!(status: :draft, publishable_timestamp_column => nil)
  end
end
