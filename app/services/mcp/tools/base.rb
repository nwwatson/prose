module Mcp
  module Tools
    class Base < MCP::Tool
      class << self
        private

        def find_post(identifier)
          if identifier.match?(/\A\d+\z/)
            Post.find(identifier)
          else
            Post.find_by!(slug: identifier)
          end
        end

        def with_post(identifier)
          post = find_post(identifier)
          yield post
        rescue ActiveRecord::RecordNotFound
          failure("Post not found: #{identifier}")
        end

        def find_category(name_or_slug)
          Category.find_by(name: name_or_slug) || Category.find_by(slug: name_or_slug)
        end

        def find_or_create_tags(names)
          names.map { |name| Tag.find_or_create_by!(name: name.strip) }
        end

        def decode_upload(data:, filename:, content_type: nil)
          io = StringIO.new(Base64.decode64(data))
          resolved_content_type = content_type || Marcel::MimeType.for(name: filename)
          [ io, resolved_content_type ]
        end

        def success(payload)
          MCP::Tool::Response.new([ { type: "text", text: payload.to_json } ])
        end

        def failure(message)
          MCP::Tool::Response.new([ { type: "text", text: { error: message }.to_json } ], error: true)
        end
      end
    end
  end
end
