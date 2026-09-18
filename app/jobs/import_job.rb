class ImportJob < ApplicationJob
  queue_as :default

  discard_on ActiveJob::DeserializationError

  def perform(import)
    import.mark_processing!
    broadcast(import)

    stats = import.file.open do |file|
      import.importer.new(io: file, user: import.user, site_url: import.site_url).call
    end
    import.complete_with!(stats)
  rescue StandardError => error
    import.fail_with!(error)
    Rails.logger.error("[ImportJob] Import #{import.id} failed: #{error.class}: #{error.message}")
  ensure
    broadcast(import) if import&.persisted?
  end

  private

  def broadcast(import)
    Turbo::StreamsChannel.broadcast_replace_to(
      "imports",
      target: ActionView::RecordIdentifier.dom_id(import),
      partial: "admin/imports/import",
      locals: { import: import }
    )
  end
end
