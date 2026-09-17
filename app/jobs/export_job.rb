class ExportJob < ApplicationJob
  queue_as :default

  discard_on ActiveJob::DeserializationError

  def perform(export)
    export.mark_processing!
    broadcast(export)

    tempfile = export.exporter.call
    export.complete_with!(tempfile)
  rescue StandardError => error
    export.fail_with!(error)
    Rails.logger.error("[ExportJob] Export #{export.id} failed: #{error.class}: #{error.message}")
  ensure
    tempfile&.close!
    broadcast(export) if export&.persisted?
  end

  private

  def broadcast(export)
    Turbo::StreamsChannel.broadcast_replace_to(
      "exports",
      target: ActionView::RecordIdentifier.dom_id(export),
      partial: "admin/exports/export",
      locals: { export: export }
    )
  end
end
