module Post::Publishable
  extend ActiveSupport::Concern

  included do
    scope :live, -> {
      published.where(published_at: ..Time.current)
        .or(scheduled.where(published_at: ..Time.current))
    }
    scope :ready_to_publish, -> { scheduled.where(published_at: ..Time.current) }

    validate :published_at_must_be_future, if: -> { scheduled? && published_at_changed? }
  end

  def publish!
    update!(status: :published, published_at: published_at || Time.current)
    SendPostNotificationsJob.perform_later(id)
  end

  def schedule!(time)
    update!(status: :scheduled, published_at: time)
  end

  def revert_to_draft!
    update!(status: :draft, published_at: nil)
  end

  private

  def published_at_must_be_future
    if published_at.present? && published_at <= Time.current
      errors.add(:published_at, "must be in the future")
    end
  end
end
