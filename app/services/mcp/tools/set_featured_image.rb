module Mcp
  module Tools
    class SetFeaturedImage < Base
      description "Set or replace the featured image for a blog post. Accepts a base64-encoded image."

      input_schema(
        properties: {
          identifier: { type: "string", description: "Post slug or numeric ID" },
          filename: { type: "string", description: "Image filename with extension (e.g., 'hero.jpg')" },
          data: { type: "string", description: "Base64-encoded image content" },
          content_type: { type: "string", description: "MIME type (e.g., 'image/jpeg'). Auto-detected if omitted." }
        },
        required: %w[identifier filename data]
      )

      class << self
        def call(server_context:, identifier:, filename:, data:, **params)
          with_post(identifier) do |post|
            io, content_type = decode_upload(data: data, filename: filename, content_type: params[:content_type])

            post.featured_image.attach(
              io: io,
              filename: filename,
              content_type: content_type
            )

            result = Mcp::PostSerializer.call(post.reload)
            result[:featured_image_attached] = true
            success(result)
          end
        end
      end
    end
  end
end
