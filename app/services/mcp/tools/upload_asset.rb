module Mcp
  module Tools
    class UploadAsset < Base
      description "Upload a file (image, audio, video) as a base64-encoded string. Returns the URL and a markdown snippet for embedding."

      input_schema(
        properties: {
          filename: { type: "string", description: "Filename with extension (e.g., 'photo.jpg')" },
          data: { type: "string", description: "Base64-encoded file content" },
          content_type: { type: "string", description: "MIME type (e.g., 'image/jpeg'). Auto-detected from filename if omitted." }
        },
        required: %w[filename data]
      )

      class << self
        def call(server_context:, filename:, data:, **params)
          io, content_type = decode_upload(data: data, filename: filename, content_type: params[:content_type])

          blob = ActiveStorage::Blob.create_and_upload!(
            io: io,
            filename: filename,
            content_type: content_type
          )

          url = Rails.application.routes.url_helpers.rails_blob_path(blob, only_path: true)
          markdown = "![#{filename}](#{url})"

          success({ url: url, filename: filename, content_type: blob.content_type, byte_size: blob.byte_size, markdown: markdown })
        rescue => e
          failure(e.message)
        end
      end
    end
  end
end
