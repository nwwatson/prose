module Post::Publishable
  extend ActiveSupport::Concern

  included do
    scope :live, -> { published.where("published_at <= ?", Time.current) }
    scope :ready_to_publish, -> { scheduled.where("scheduled_at <= ?", Time.current) }

    validate :scheduled_at_must_be_future, if: -> { scheduled? && scheduled_at_changed? }
  end

  def publish!
    update!(status: :published, published_at: Time.current, scheduled_at: nil)
    SendPostNotificationsJob.perform_later(id)
  end

  def schedule!(time)
    update!(status: :scheduled, scheduled_at: time)
  end

  def revert_to_draft!
    update!(status: :draft, published_at: nil, scheduled_at: nil)
  end

  private

  def scheduled_at_must_be_future
    if scheduled_at.present? && scheduled_at <= Time.current
      errors.add(:scheduled_at, "must be in the future")
    end
  end
end
