module Newsletter::Sendable
  extend ActiveSupport::Concern
  include Publishable

  included do
    publishes_at :scheduled_for

    scope :ready_to_send, -> { scheduled.where("scheduled_for <= ?", Time.current) }
  end

  def send_newsletter!
    update!(status: :sending, sent_at: Time.current, scheduled_for: nil)
    SendNewsletterJob.perform_later(id)
  end

  def mark_sent!(count)
    update!(status: :sent, recipients_count: count)
  end

  def revert_to_draft!
    update!(status: :draft, sent_at: nil, scheduled_for: nil)
  end

  def target_subscribers
    segment.present? ? segment.resolve : Subscriber.confirmed
  end

  def sendable?
    draft? || scheduled?
  end
end
