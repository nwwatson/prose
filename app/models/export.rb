class Export < ApplicationRecord
  RETENTION_LIMIT = 10

  enum :format, { markdown: 0, json: 1 }, prefix: :format, validate: true
  enum :status, { pending: 0, processing: 1, completed: 2, failed: 3 }

  belongs_to :user
  has_one_attached :file

  scope :recent, -> { order(created_at: :desc) }

  after_create_commit :prune_old_exports

  def self.exporter_for(format)
    case format.to_s
    when "markdown" then Exports::MarkdownExporter
    when "json" then Exports::JsonExporter
    else raise ArgumentError, "Unknown export format: #{format}"
    end
  end

  def exporter
    self.class.exporter_for(format)
  end

  def download_filename
    "prose-export-#{created_at.to_date.iso8601}-#{id}.#{file_extension}"
  end

  def file_extension
    format_markdown? ? "zip" : "json"
  end

  def content_type
    format_markdown? ? "application/zip" : "application/json"
  end

  def mark_processing!
    update!(status: :processing, error_message: nil)
  end

  def complete_with!(io)
    file.attach(io: io, filename: download_filename, content_type: content_type)
    update!(status: :completed, completed_at: Time.current)
  end

  def fail_with!(error)
    update!(status: :failed, error_message: error.message.to_s.truncate(500))
  end

  private

  def prune_old_exports
    # Destroying purges the attached file (has_one_attached defaults to purge_later).
    self.class.where.not(id: self.class.recent.limit(RETENTION_LIMIT).select(:id)).destroy_all
  end
end
