module Newsletter::Sendable
  extend ActiveSupport::Concern

  included do
    scope :ready_to_send, -> { scheduled.where("scheduled_for <= ?", Time.current) }

    validate :scheduled_for_must_be_future, if: -> { scheduled? && scheduled_for_changed? }
  end

  def send_newsletter!
    update!(status: :sending, sent_at: Time.current, scheduled_for: nil)
    SendNewsletterJob.perform_later(id)
  end

  def schedule!(time)
    update!(status: :scheduled, scheduled_for: time)
  end

  def mark_sent!(count)
    update!(status: :sent, recipients_count: count)
  end

  def revert_to_draft!
    update!(status: :draft, sent_at: nil, scheduled_for: nil)
  end

  def sendable?
    draft? || scheduled?
  end

  private

  def scheduled_for_must_be_future
    if scheduled_for.present? && scheduled_for <= Time.current
      errors.add(:scheduled_for, "must be in the future")
    end
  end
end
