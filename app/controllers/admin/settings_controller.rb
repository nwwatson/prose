module Admin
  class SettingsController < BaseController
    def edit
      @site_setting = SiteSetting.current
    end

    def update
      @site_setting = SiteSetting.current
      if @site_setting.update(filtered_site_setting_params)
        redirect_to edit_admin_settings_path, notice: "Settings saved."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def site_setting_params
      params.require(:site_setting).permit(
        :site_name, :site_description, :default_og_image,
        :heading_font, :subtitle_font, :body_font,
        :heading_font_size, :subtitle_font_size, :body_font_size,
        :background_color,
        :claude_api_key, :gemini_api_key, :openai_api_key, :ai_model, :ai_max_tokens, :image_model
      )
    end

    def filtered_site_setting_params
      filtered = site_setting_params.to_h
      # Don't overwrite encrypted keys with the placeholder mask
      %w[claude_api_key gemini_api_key openai_api_key].each do |key|
        filtered.delete(key) if filtered[key] == "\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022"
        # Allow blank to clear the key
      end
      filtered
    end
  end
end
