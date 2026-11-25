class SendScheduledNewslettersJob < ApplicationJob
  queue_as :default

  def perform
    Newsletter.ready_to_send.find_each do |newsletter|
      newsletter.send_newsletter!
    rescue => e
      # One bad record must not block the others; it is retried on the next run.
      Rails.logger.error("[Scheduled Newsletters] Failed to send newsletter #{newsletter.id}: #{e.message}")
      Rails.error.report(e, handled: true, context: { newsletter_id: newsletter.id })
    end
  end
end
