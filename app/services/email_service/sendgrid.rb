class EmailService::Sendgrid < EmailService::Base
  def initialize(api_key:)
    @api_key = api_key
  end

  def deliver_newsletter(newsletter, subscriber)
    mailer = NewsletterMailer.campaign(subscriber, newsletter)
    message = mailer.message

    send_email(
      to: subscriber.email,
      subject: newsletter.title,
      html: message.html_part&.body&.to_s || message.body.to_s,
      text: message.text_part&.body&.to_s || "",
      headers: extract_headers(message),
      metadata: { newsletter_id: newsletter.id, subscriber_id: subscriber.id }
    )
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

  private

  def from_address
    ENV.fetch("SMTP_FROM", "noreply@example.com")
  end

  def extract_headers(message)
    headers = {}
    if message.header["List-Unsubscribe"]
      headers["List-Unsubscribe"] = message.header["List-Unsubscribe"].value
    end
    if message.header["List-Unsubscribe-Post"]
      headers["List-Unsubscribe-Post"] = message.header["List-Unsubscribe-Post"].value
    end
    headers
  end
end
