class EmailService::Sendgrid::WebhookProcessor
  def process(payload)
    events = payload.is_a?(Array) ? payload : [ payload ]

    events.each do |event|
      process_event(event)
    end
  end

  private

  def process_event(event)
    newsletter_id = event.dig("unique_args", "newsletter_id") || event["newsletter_id"]
    subscriber_id = event.dig("unique_args", "subscriber_id") || event["subscriber_id"]

    return unless newsletter_id.present? && subscriber_id.present?

    delivery = NewsletterDelivery.find_by(
      newsletter_id: newsletter_id,
      subscriber_id: subscriber_id
    )
    return unless delivery

    case event["event"]
    when "open"
      record_open(delivery)
    when "click"
      record_click(delivery)
    when "bounce", "dropped"
      delivery.update(bounced_at: Time.current)
    when "spamreport", "unsubscribe"
      delivery.subscriber.unsubscribe!
    end
  end

  # Open and click events for one delivery can arrive concurrently, so both are
  # written in SQL rather than computed from the loaded record.
  def record_open(delivery)
    NewsletterDelivery.where(id: delivery.id).update_all([
      "open_count = COALESCE(open_count, 0) + 1, opened_at = COALESCE(opened_at, :now), updated_at = :now",
      { now: Time.current }
    ])
  end

  # Only the first click is recorded.
  def record_click(delivery)
    now = Time.current
    NewsletterDelivery.where(id: delivery.id, clicked_at: nil).update_all(clicked_at: now, updated_at: now)
  end
end
