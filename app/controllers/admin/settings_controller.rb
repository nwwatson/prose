module Admin
  class SettingsController < BaseController
    def edit
      @site_setting = SiteSetting.current
    end

    def update
      @site_setting = SiteSetting.current
      if @site_setting.update(site_setting_params)
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
        :heading_font_size, :subtitle_font_size, :body_font_size
      )
    end
  end
end
