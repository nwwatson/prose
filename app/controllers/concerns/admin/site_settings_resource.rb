module Admin
  module SiteSettingsResource
    extend ActiveSupport::Concern

    included do
      before_action :set_site_setting
    end

    def edit
    end

    def update
      @site_setting.assign_attributes_ignoring_mask(site_setting_params)
      if @site_setting.save
        redirect_to redirect_path, notice: t(notice_key)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_site_setting
      @site_setting = SiteSetting.current
    end
  end
end
