class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("SMTP_FROM", "noreply@example.com")
  layout "mailer"

  private

  def load_email_branding
    site = SiteSetting.current
    @site_name = site.site_name
    @email_accent_color = site.email_accent_color.presence || "#18181b"
    @email_background_color = site.email_background_color.presence || "#f4f4f5"
    @email_body_text_color = site.email_body_text_color.presence || "#3f3f46"
    @email_heading_color = site.email_heading_color.presence || "#18181b"
    @email_font_family = site.email_font_stack
    @email_footer_text = site.email_footer_text.presence
    @email_logo_url = site.email_header_logo_url
  end

  def generate_unsubscribe_url(subscriber)
    token = Rails.application.message_verifier("unsubscribe").generate(
      subscriber.id,
      expires_in: 30.days
    )
    unsubscribe_url(token: token)
  end
end
