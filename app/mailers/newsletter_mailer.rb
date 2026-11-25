class NewsletterMailer < ApplicationMailer
  layout "newsletter_mailer"

  def campaign(subscriber, newsletter)
    @subscriber = subscriber
    @newsletter = newsletter
    @email_settings = newsletter.email_settings
    @site_name = @email_settings[:site_name]
    prepare_subscriber_links(subscriber)

    mail(to: subscriber.email, subject: newsletter.title)
  end
end
