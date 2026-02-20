module Mcp
  module Tools
    class SetFeaturedImage < MCP::Tool
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
          post = find_post(identifier)
          decoded = Base64.decode64(data)
          content_type = params[:content_type] || Marcel::MimeType.for(name: filename)

          post.featured_image.attach(
            io: StringIO.new(decoded),
            filename: filename,
            content_type: content_type
          )

          result = Mcp::PostSerializer.call(post.reload)
          result[:featured_image_attached] = true
          MCP::Tool::Response.new([ { type: "text", text: result.to_json } ])
        rescue ActiveRecord::RecordNotFound
          MCP::Tool::Response.new([ { type: "text", text: { error: "Post not found: #{identifier}" }.to_json } ], error: true)
        end

        private

        def find_post(identifier)
          if identifier.match?(/\A\d+\z/)
            Post.find(identifier)
          else
            Post.find_by!(slug: identifier)
          end
        end
      end
    end
  end
end
