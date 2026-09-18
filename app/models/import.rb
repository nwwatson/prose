class Import < ApplicationRecord
  MAX_FILE_SIZE = 50.megabytes
  ACCEPTED_FILES = {
    "wordpress" => { content_types: %w[application/xml text/xml application/rss+xml], extensions: %w[xml] },
    "ghost" => { content_types: %w[application/json], extensions: %w[json] },
    "substack" => { content_types: %w[application/zip application/x-zip-compressed text/csv], extensions: %w[zip csv] }
  }.freeze
  MAX_WARNINGS = 50

  enum :source, { wordpress: 0, ghost: 1, substack: 2 }, prefix: :source, validate: true
  enum :status, { pending: 0, processing: 1, completed: 2, failed: 3 }

  belongs_to :user
  has_one_attached :file

  normalizes :site_url, with: ->(url) { url.strip.chomp("/").presence }

  validate :file_is_acceptable, on: :create
  validate :site_url_is_http, if: :site_url?

  scope :recent, -> { order(created_at: :desc) }

  def self.importer_for(source)
    case source.to_s
    when "wordpress" then Imports::WordpressImporter
    when "ghost" then Imports::GhostImporter
    when "substack" then Imports::SubstackImporter
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
    errors.add(:file, :"invalid_#{source}_type") if ACCEPTED_FILES.key?(source) && !accepted_file_type?
  end

  def accepted_file_type?
    accepted = ACCEPTED_FILES.fetch(source)
    extension = file.blob.filename.extension.to_s.downcase
    accepted[:content_types].include?(file.blob.content_type) || accepted[:extensions].include?(extension)
  end

  def site_url_is_http
    uri = URI.parse(site_url)
    errors.add(:site_url, :invalid) unless uri.is_a?(URI::HTTP) && uri.host.present?
  rescue URI::InvalidURIError
    errors.add(:site_url, :invalid)
  end
end
