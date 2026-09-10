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
      delivery.update(
        opened_at: delivery.opened_at || Time.current,
        open_count: delivery.open_count + 1
      )
    when "click"
      delivery.update(
        clicked_at: delivery.clicked_at || Time.current
      )
    when "bounce", "dropped"
      delivery.update(bounced_at: Time.current)
    when "spamreport", "unsubscribe"
      subscriber = delivery.subscriber
      subscriber.unsubscribe! if subscriber.respond_to?(:unsubscribe!)
    end
  end
end
