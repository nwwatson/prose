module Publishable
  extend ActiveSupport::Concern

  included do
    class_attribute :publishable_timestamp_column, default: :published_at
  end

  class_methods do
    # `live_statuses` are the statuses `live` accepts once the timestamp has
    # passed; Post also counts `scheduled` ones the publish job hasn't reached.
    def publishes_at(column = :published_at, live_statuses: :published)
      self.publishable_timestamp_column = column

      scope :live, -> { where(status: live_statuses).where(column => ..Time.current) }

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
