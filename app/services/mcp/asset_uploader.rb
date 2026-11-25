module Mcp
  # Stores an uploaded file as an Active Storage blob and describes it, for the
  # `upload_asset` MCP tool and `POST /api/v1/assets`.
  class AssetUploader
    def self.call(io:, filename:, content_type:)
      blob = ActiveStorage::Blob.create_and_upload!(io: io, filename: filename, content_type: content_type)
      url = Rails.application.routes.url_helpers.rails_blob_path(blob, only_path: true)

      { url: url, filename: blob.filename.to_s, content_type: blob.content_type, byte_size: blob.byte_size }
    end
  end
end
