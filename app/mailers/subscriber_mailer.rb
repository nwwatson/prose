class SubscriberMailer < ApplicationMailer
  def confirmation(subscriber)
    @subscriber = subscriber
    @magic_link = subscriber_session_url(token: subscriber.auth_token)
    load_email_branding
    mail(to: subscriber.email, subject: t("subscriber_mailer.confirmation.subject", site_name: @site_name))
  end

  def magic_link(subscriber)
    @subscriber = subscriber
    @magic_link = subscriber_session_url(token: subscriber.auth_token)
    load_email_branding
    mail(to: subscriber.email, subject: t("subscriber_mailer.magic_link.sign_in_to", site_name: @site_name))
  end
end
