module Newsletter::Templatable
  extend ActiveSupport::Concern

  included do
    validates :template, inclusion: { in: SiteSetting::EmailBranding::EMAIL_TEMPLATES.keys }, allow_nil: true
    validates :accent_color, format: { with: SiteSetting::EmailBranding::HEX_COLOR_FORMAT }, allow_nil: true, allow_blank: true
    validates :preheader_text, length: { maximum: 150 }, allow_nil: true
  end

  def resolved_template
    template.presence || SiteSetting.current.email_default_template.presence || "minimal"
  end

  def resolved_accent_color
    accent_color.presence || SiteSetting.current.email_accent_color.presence || "#18181b"
  end

  def resolved_preheader_text
    preheader_text.presence || SiteSetting.current.email_preheader_text.presence || ""
  end

  def email_settings
    site = SiteSetting.current
    {
      template: resolved_template,
      accent_color: resolved_accent_color,
      preheader_text: resolved_preheader_text,
      background_color: site.email_background_color.presence || "#f4f4f5",
      body_text_color: site.email_body_text_color.presence || "#3f3f46",
      heading_color: site.email_heading_color.presence || "#18181b",
      font_family: site.email_font_stack,
      footer_text: site.email_footer_text.presence || "",
      site_name: site.site_name,
      logo_url: site.email_header_logo_url,
      social_twitter: site.email_social_twitter.presence,
      social_github: site.email_social_github.presence,
      social_linkedin: site.email_social_linkedin.presence,
      social_website: site.email_social_website.presence
    }
  end
end
