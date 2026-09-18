module Admin
  class ImportsController < BaseController
    before_action :require_admin

    def index
      @import = Import.new(source: :wordpress)
      @imports = Import.recent.includes(user: :identity)
    end

    def create
      @import = Import.new(import_params.merge(user: current_user))

      if @import.save
        ImportJob.perform_later(@import)
        redirect_to admin_imports_path, notice: t("flash.admin.imports.started")
      else
        @imports = Import.recent.includes(user: :identity)
        render :index, status: :unprocessable_entity
      end
    end

    def destroy
      Import.find(params[:id]).destroy
      redirect_to admin_imports_path, notice: t("flash.admin.imports.deleted")
    end

    private

    def import_params
      params.fetch(:import, {}).permit(:source, :file)
    end
  end
end
