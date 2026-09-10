module Newsletter::Templatable
  extend ActiveSupport::Concern

  included do
    validates :template, inclusion: { in: SiteSetting::EmailBranding::EMAIL_TEMPLATES.keys }, allow_nil: true
    validates :accent_color, format: { with: SiteSetting::EmailBranding::HEX_COLOR_FORMAT }, allow_nil: true, allow_blank: true
    validates :preheader_text, length: { maximum: 150 }, allow_nil: true
  end

  def resolved_template(site = SiteSetting.current)
    template.presence || site.email_default_template.presence || "minimal"
  end

  def resolved_accent_color(site = SiteSetting.current)
    accent_color.presence || site.email_accent_color.presence || "#18181b"
  end

  def resolved_preheader_text(site = SiteSetting.current)
    preheader_text.presence || site.email_preheader_text.presence || ""
  end

  def email_settings
    site = SiteSetting.current
    site.email_branding.merge(
      template: resolved_template(site),
      accent_color: resolved_accent_color(site),
      preheader_text: resolved_preheader_text(site),
      social_twitter: site.email_social_twitter.presence,
      social_github: site.email_social_github.presence,
      social_linkedin: site.email_social_linkedin.presence,
      social_website: site.email_social_website.presence
    )
  end
end
