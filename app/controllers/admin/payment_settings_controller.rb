module Admin
  class PaymentSettingsController < BaseController
    def edit
      @site_setting = SiteSetting.current
    end

    def update
      @site_setting = SiteSetting.current
      if @site_setting.update(filtered_payment_params)
        redirect_to edit_admin_payment_settings_path, notice: t("flash.admin.payment_settings.saved")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def payment_params
      params.require(:site_setting).permit(
        :stripe_secret_key, :stripe_publishable_key, :stripe_webhook_secret, :payments_currency
      )
    end

    def filtered_payment_params
      filtered = payment_params.to_h
      %w[stripe_secret_key stripe_publishable_key stripe_webhook_secret].each do |key|
        filtered.delete(key) if filtered[key] == "\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022"
      end
      filtered
    end
  end
end
