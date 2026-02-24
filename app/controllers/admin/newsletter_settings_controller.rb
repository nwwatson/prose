module Admin
  class NewsletterSettingsController < BaseController
    def edit
      @site_setting = SiteSetting.current
    end

    def update
      @site_setting = SiteSetting.current
      if @site_setting.update(filtered_site_setting_params)
        redirect_to edit_admin_newsletter_settings_path, notice: t("flash.admin.newsletter_settings.saved")
      else
        render :edit, status: :unprocessable_entity
      end
    end

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

    def filtered_site_setting_params
      filtered = site_setting_params.to_h
      %w[sendgrid_api_key].each do |key|
        filtered.delete(key) if filtered[key] == "\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022"
      end
      filtered
    end
  end
end
