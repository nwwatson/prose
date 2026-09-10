class EmailService::Smtp < EmailService::Base
  def deliver_newsletter(newsletter, subscriber)
    NewsletterMailer.campaign(subscriber, newsletter).deliver_later
  end
end
