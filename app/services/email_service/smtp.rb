class EmailService::Smtp < EmailService::Base
  def send_email(to:, subject:, html:, text:, headers: {}, metadata: {})
    NewsletterMailer.campaign(
      Subscriber.find(metadata[:subscriber_id]),
      Newsletter.find(metadata[:newsletter_id])
    ).deliver_later
  end

  def process_webhook(payload)
    # SMTP doesn't support webhooks
  end
end
