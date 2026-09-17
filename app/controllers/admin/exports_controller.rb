module Admin
  class ExportsController < BaseController
    before_action :require_admin

    def index
      @exports = Export.recent.includes(file_attachment: :blob, user: :identity)
    end

    def create
      export = Export.new(format: params[:format_type], user: current_user)

      if export.save
        ExportJob.perform_later(export)
        redirect_to admin_exports_path, notice: t("flash.admin.exports.started")
      else
        redirect_to admin_exports_path, alert: t("flash.admin.exports.invalid_format")
      end
    end

    def destroy
      Export.find(params[:id]).destroy
      redirect_to admin_exports_path, notice: t("flash.admin.exports.deleted")
    end
  end
end
