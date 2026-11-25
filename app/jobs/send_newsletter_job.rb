# Sends a newsletter to its target subscribers, one at a time, with
# at-least-once delivery:
#
# - A NewsletterDelivery row is written only after the provider has accepted
#   the message, so a row means "delivered". It is the only write per
#   recipient.
# - A provider error for one subscriber is logged and the loop moves on. If
#   any recipient failed, the job raises PartialDeliveryError and `retry_on`
#   runs it again later. Every run starts from the subscribers that have no
#   row yet, so a retry (or a rerun after a crash) resumes with the undelivered
#   recipients and never re-sends to a delivered one.
# - The remaining duplicate window: the provider accepts a message and the
#   process dies before the row is written. That recipient is sent to again on
#   the next run.
# - Once retries are exhausted the newsletter is marked sent with the number
#   actually delivered; the subscribers that never accepted are reported.
class SendNewsletterJob < ApplicationJob
  MAX_ATTEMPTS = 5
  # Stop a run early when the provider rejects this many in a row (a revoked
  # API key, an SMTP outage) instead of trying every remaining subscriber.
  MAX_CONSECUTIVE_FAILURES = 10

  class PartialDeliveryError < StandardError; end

  queue_as :default

  # Two runs for one newsletter at once would both see the same subscribers as
  # pending and both send to them. The duration only has to outlast one run.
  limits_concurrency key: ->(newsletter_id) { "send_newsletter/#{newsletter_id}" }, duration: 6.hours

  retry_on PartialDeliveryError, wait: :polynomially_longer, attempts: MAX_ATTEMPTS do |job, error|
    newsletter = Newsletter.find_by(id: job.arguments.first)
    newsletter.mark_sent! if newsletter&.sending?
    Rails.error.report(error, handled: true, context: { newsletter_id: job.arguments.first })
  end

  def perform(newsletter_id)
    newsletter = Newsletter.find_by(id: newsletter_id)
    # A newsletter that is no longer sending was finished (or reverted) by an
    # earlier run; sending now would only reach people who subscribed since.
    return unless newsletter&.sending?

    failed = deliver_to_pending(newsletter)

    if failed.positive?
      raise PartialDeliveryError, "Newsletter #{newsletter.id}: the email provider did not accept #{failed} message(s)"
    end

    newsletter.mark_sent!
  end

  private

  def deliver_to_pending(newsletter)
    provider = EmailService.provider
    failed = 0
    consecutive_failures = 0

    pending_subscribers(newsletter).find_each do |subscriber|
      # The rest stay pending for the retry.
      break if consecutive_failures >= MAX_CONSECUTIVE_FAILURES

      begin
        provider.deliver_newsletter(newsletter, subscriber)
      rescue StandardError => e
        failed += 1
        consecutive_failures += 1
        Rails.logger.warn("[SendNewsletterJob] newsletter #{newsletter.id} subscriber #{subscriber.id}: #{e.class}: #{e.message}")
        next
      end

      consecutive_failures = 0
      record_delivery(newsletter, subscriber)
    end

    failed
  end

  def record_delivery(newsletter, subscriber)
    now = Time.current
    NewsletterDelivery.insert(
      { newsletter_id: newsletter.id, subscriber_id: subscriber.id, sent_at: now, created_at: now, updated_at: now },
      unique_by: %i[newsletter_id subscriber_id]
    )
  end

  def pending_subscribers(newsletter)
    newsletter.target_subscribers.where.not(id: newsletter.newsletter_deliveries.select(:subscriber_id))
  end
end
