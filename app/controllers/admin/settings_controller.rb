module Admin
  class SettingsController < BaseController
    include SiteSettingsResource

    private

    def site_setting_params
      params.require(:site_setting).permit(
        :site_name, :site_description, :default_og_image,
        :heading_font, :subtitle_font, :body_font,
        :heading_font_size, :subtitle_font_size, :body_font_size,
        :background_color, :theme_mode,
        :dark_theme, :dark_bg_color, :dark_text_color, :dark_accent_color,
        :claude_api_key, :gemini_api_key, :openai_api_key, :ai_model, :ai_max_tokens, :image_model,
        :stripe_secret_key, :stripe_publishable_key, :stripe_webhook_secret, :payments_currency,
        :locale,
        :block_crawlers
      )
    end

    def redirect_path
      edit_admin_settings_path
    end

    def notice_key
      "flash.admin.settings.saved"
    end
  end
end
