class ApplicationMailer < ActionMailer::Base
  default from: EmailService.from_address
  layout "mailer"

  private

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

  def set_list_unsubscribe_headers(url)
    headers["List-Unsubscribe"] = "<#{url}>"
    headers["List-Unsubscribe-Post"] = "List-Unsubscribe=One-Click"
  end

  def generate_unsubscribe_url(subscriber)
    token = Rails.application.message_verifier("unsubscribe").generate(
      subscriber.id,
      expires_in: 30.days
    )
    unsubscribe_url(token: token)
  end
end
