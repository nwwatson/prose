class NewsletterMailer < ApplicationMailer
  helper MailerHelper

  layout "newsletter_mailer"

  def campaign(subscriber, newsletter)
    @subscriber = subscriber
    @newsletter = newsletter
    @email_settings = newsletter.email_settings
    @site_name = @email_settings[:site_name]
    @unsubscribe_url = generate_unsubscribe_url(subscriber)

    headers["List-Unsubscribe"] = "<#{@unsubscribe_url}>"
    headers["List-Unsubscribe-Post"] = "List-Unsubscribe=One-Click"

    mail(to: subscriber.email, subject: newsletter.title)
  end
end
