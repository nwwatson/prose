class Import < ApplicationRecord
  MAX_FILE_SIZE = 50.megabytes
  ALLOWED_CONTENT_TYPES = %w[application/xml text/xml application/rss+xml].freeze
  MAX_WARNINGS = 50

  enum :source, { wordpress: 0 }, prefix: :source, validate: true
  enum :status, { pending: 0, processing: 1, completed: 2, failed: 3 }

  belongs_to :user
  has_one_attached :file

  validate :file_is_acceptable, on: :create

  scope :recent, -> { order(created_at: :desc) }

  def self.importer_for(source)
    case source.to_s
    when "wordpress" then Imports::WordpressImporter
    else raise ArgumentError, "Unknown import source: #{source}"
    end
  end

  def importer
    self.class.importer_for(source)
  end

  def stat(key)
    stats.fetch(key.to_s, 0)
  end

  def warnings
    Array(stats["warnings"])
  end

  def mark_processing!
    update!(status: :processing, error_message: nil)
  end

  def complete_with!(result_stats)
    update!(status: :completed, stats: result_stats, completed_at: Time.current)
  end

  def fail_with!(error, result_stats = stats)
    update!(status: :failed, stats: result_stats, error_message: error.message.to_s.truncate(500))
  end

  private

  def file_is_acceptable
    unless file.attached?
      errors.add(:file, :blank)
      return
    end

    errors.add(:file, :too_large, count: MAX_FILE_SIZE / 1.megabyte) if file.blob.byte_size > MAX_FILE_SIZE
    errors.add(:file, :invalid_type) unless xml_file?
  end

  def xml_file?
    ALLOWED_CONTENT_TYPES.include?(file.blob.content_type) || file.blob.filename.extension.casecmp?("xml")
  end
end
