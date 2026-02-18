class SubscriberMailer < ApplicationMailer
  def confirmation(subscriber)
    @subscriber = subscriber
    @magic_link = subscriber_session_url(token: subscriber.auth_token)
    @site_name = SiteSetting.current.site_name
    mail(to: subscriber.email, subject: "Confirm your subscription to #{@site_name}")
  end

  def magic_link(subscriber)
    @subscriber = subscriber
    @magic_link = subscriber_session_url(token: subscriber.auth_token)
    @site_name = SiteSetting.current.site_name
    mail(to: subscriber.email, subject: "Sign in to #{@site_name}")
  end
end
