class EmailService::Sendgrid < EmailService::Base
  def initialize(api_key:)
    @api_key = api_key
  end

  def send_email(to:, subject:, html:, text:, headers: {}, metadata: {})
    mail = SendGrid::Mail.new
    mail.from = SendGrid::Email.new(email: from_address)
    mail.subject = subject

    personalization = SendGrid::Personalization.new
    personalization.add_to(SendGrid::Email.new(email: to))
    personalization.add_custom_arg(SendGrid::CustomArg.new(key: "newsletter_id", value: metadata[:newsletter_id].to_s)) if metadata[:newsletter_id]
    personalization.add_custom_arg(SendGrid::CustomArg.new(key: "subscriber_id", value: metadata[:subscriber_id].to_s)) if metadata[:subscriber_id]
    mail.add_personalization(personalization)

    mail.add_content(SendGrid::Content.new(type: "text/plain", value: text))
    mail.add_content(SendGrid::Content.new(type: "text/html", value: html))

    tracking = SendGrid::TrackingSettings.new
    tracking.open_tracking = SendGrid::OpenTracking.new(enable: true)
    tracking.click_tracking = SendGrid::ClickTracking.new(enable: true, enable_text: false)
    mail.tracking_settings = tracking

    headers.each do |key, value|
      mail.add_header(SendGrid::Header.new(key: key.to_s, value: value.to_s))
    end

    sg = SendGrid::API.new(api_key: @api_key)
    response = sg.client.mail._("send").post(request_body: mail.to_json)

    unless response.status_code.to_i.between?(200, 299)
      Rails.logger.error("[SendGrid] Failed to send email to #{to}: #{response.status_code} #{response.body}")
    end

    response
  end

  def process_webhook(payload)
    events = payload.is_a?(Array) ? payload : [ payload ]

    events.each do |event|
      process_event(event)
    end
  end

  private

  def from_address
    ENV.fetch("SMTP_FROM", "noreply@example.com")
  end

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
