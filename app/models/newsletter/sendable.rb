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

  # The campaign's list (or every confirmed subscriber), narrowed by its segment.
  def target_subscribers
    audience = mailing_list ? mailing_list.recipients : Subscriber.confirmed
    segment ? segment.resolve(audience) : audience
  end

  def sendable?
    draft? || scheduled?
  end
end
