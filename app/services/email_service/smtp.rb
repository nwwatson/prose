class EmailService::Smtp < EmailService::Base
  # Delivers synchronously so an SMTP rejection raises here, where
  # SendNewsletterJob can retry it, instead of inside a fire-and-forget mail
  # job. Delivery errors are raised even where `raise_delivery_errors` is off
  # (development), since a swallowed error would be recorded as delivered.
  def deliver_newsletter(newsletter, subscriber)
    mail = NewsletterMailer.campaign(subscriber, newsletter)
    mail.message.raise_delivery_errors = true
    mail.deliver_now
  end
end
