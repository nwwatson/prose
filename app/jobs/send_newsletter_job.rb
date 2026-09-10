class SendNewsletterJob < ApplicationJob
  queue_as :default

  def perform(newsletter_id)
    newsletter = Newsletter.find(newsletter_id)
    provider = EmailService.provider
    use_sendgrid = SiteSetting.current.sendgrid?
    count = 0

    pending_subscribers(newsletter).find_each do |subscriber|
      begin
        newsletter.newsletter_deliveries.create!(subscriber: subscriber, sent_at: Time.current)
      rescue ActiveRecord::RecordNotUnique
        next
      end

      deliver_to(subscriber, newsletter, provider: provider, use_sendgrid: use_sendgrid)
      count += 1
    end

    newsletter.mark_sent!(count)
  end

  private

  def pending_subscribers(newsletter)
    newsletter.target_subscribers.where.not(id: newsletter.newsletter_deliveries.select(:subscriber_id))
  end

  def deliver_to(subscriber, newsletter, provider:, use_sendgrid:)
    if use_sendgrid
      deliver_via_sendgrid(subscriber, newsletter, provider)
    else
      NewsletterMailer.campaign(subscriber, newsletter).deliver_later
    end
  end

  def deliver_via_sendgrid(subscriber, newsletter, provider)
    mailer = NewsletterMailer.campaign(subscriber, newsletter)
    message = mailer.message

    provider.send_email(
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
