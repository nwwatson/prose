class SendNewsletterJob < ApplicationJob
  queue_as :default

  def perform(newsletter_id)
    newsletter = Newsletter.find(newsletter_id)
    count = 0

    Subscriber.confirmed.find_each do |subscriber|
      next if newsletter.newsletter_deliveries.exists?(subscriber: subscriber)

      newsletter.newsletter_deliveries.create!(subscriber: subscriber, sent_at: Time.current)
      deliver_to(subscriber, newsletter)
      count += 1
    end

    newsletter.mark_sent!(count)
  end

  private

  def deliver_to(subscriber, newsletter)
    if SiteSetting.current.sendgrid?
      deliver_via_sendgrid(subscriber, newsletter)
    else
      NewsletterMailer.campaign(subscriber, newsletter).deliver_later
    end
  end

  def deliver_via_sendgrid(subscriber, newsletter)
    mailer = NewsletterMailer.campaign(subscriber, newsletter)
    message = mailer.message

    EmailService.provider.send_email(
      to: subscriber.email,
      subject: newsletter.title,
      html: message.html_part&.body&.to_s || message.body.to_s,
      text: message.text_part&.body&.to_s || "",
      headers: extract_headers(message),
      metadata: { newsletter_id: newsletter.id, subscriber_id: subscriber.id }
    )
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
