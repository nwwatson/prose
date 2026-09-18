module Post::Publishable
  extend ActiveSupport::Concern
  include Publishable

  included do
    publishes_at :published_at

    scope :live, -> { where(status: [ :published, :scheduled ], published_at: ..Time.current) }
    scope :ready_to_publish, -> { scheduled.where(published_at: ..Time.current) }
  end
end
