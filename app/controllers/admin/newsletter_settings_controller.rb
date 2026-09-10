module Admin
  class NewsletterSettingsController < BaseController
    include SiteSettingsResource

    private

    def site_setting_params
      params.require(:site_setting).permit(
        :email_provider, :sendgrid_api_key,
        :email_accent_color, :email_background_color, :email_body_text_color,
        :email_heading_color, :email_font_family, :email_footer_text,
        :email_preheader_text, :email_social_twitter, :email_social_github,
        :email_social_linkedin, :email_social_website, :email_default_template,
        :email_header_logo
      )
    end

    def redirect_path
      edit_admin_newsletter_settings_path
    end

    def notice_key
      "flash.admin.newsletter_settings.saved"
    end
  end
end
