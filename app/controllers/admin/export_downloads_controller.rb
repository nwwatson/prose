module Admin
  # Streams a finished export through the app instead of redirecting to an
  # Active Storage blob URL: those signed URLs never expire, and a JSON export
  # contains every subscriber's email address, so a leaked link must not keep
  # working without an admin session. Kept separate from ExportsController
  # because ActiveStorage::Streaming mixes in ActionController::Live.
  class ExportDownloadsController < BaseController
    include ActiveStorage::Streaming

    before_action :require_admin

    def show
      export = Export.completed.find(params[:id])
      return redirect_to(admin_exports_path, alert: t("flash.admin.exports.file_missing")) unless export.file.attached?

      send_blob_stream export.file.blob, disposition: :attachment
    end
  end
end
