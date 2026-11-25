class ApplicationMailer < ActionMailer::Base
  default from: EmailService.from_address
  layout "mailer"

  # Mail is rendered in jobs and in API requests as well as in site requests, so
  # the locale can't be left to whoever built the message.
  around_action :use_site_locale

  private

  def use_site_locale(&)
    I18n.with_locale(SiteSetting.current.locale, &)
  end

  def load_email_branding
    @email_settings = SiteSetting.current.email_branding
    @site_name = @email_settings[:site_name]
    @email_accent_color = @email_settings[:accent_color]
    @email_background_color = @email_settings[:background_color]
    @email_body_text_color = @email_settings[:body_text_color]
    @email_heading_color = @email_settings[:heading_color]
    @email_font_family = @email_settings[:font_family]
    @email_footer_text = @email_settings[:footer_text]
    @email_logo_url = @email_settings[:logo_url]
  end

  # The unsubscribe and preferences links every post email, digest and
  # newsletter carries, plus the one-click List-Unsubscribe headers.
  def prepare_subscriber_links(subscriber)
    @unsubscribe_url = unsubscribe_url(token: subscriber.unsubscribe_token)
    @email_preferences_url = email_preferences_url(token: subscriber.email_preferences_token)

    headers["List-Unsubscribe"] = "<#{@unsubscribe_url}>"
    headers["List-Unsubscribe-Post"] = "List-Unsubscribe=One-Click"
  end
end
