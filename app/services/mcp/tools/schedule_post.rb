module Mcp
  module Tools
    class SchedulePost < MCP::Tool
      description "Schedule a blog post for future publication. Accepts an ISO 8601 datetime string."

      input_schema(
        properties: {
          identifier: { type: "string", description: "Post slug or numeric ID" },
          published_at: { type: "string", description: "ISO 8601 datetime for publication (must be in the future)" }
        },
        required: %w[identifier published_at]
      )

      class << self
        def call(server_context:, identifier:, published_at:)
          post = find_post(identifier)
          time = Time.iso8601(published_at)
          post.schedule!(time)

          result = Mcp::PostSerializer.call(post.reload)
          MCP::Tool::Response.new([ { type: "text", text: result.to_json } ])
        rescue ActiveRecord::RecordNotFound
          MCP::Tool::Response.new([ { type: "text", text: { error: "Post not found: #{identifier}" }.to_json } ], error: true)
        rescue ArgumentError => e
          MCP::Tool::Response.new([ { type: "text", text: { error: "Invalid datetime: #{e.message}" }.to_json } ], error: true)
        rescue ActiveRecord::RecordInvalid => e
          MCP::Tool::Response.new([ { type: "text", text: { error: e.message }.to_json } ], error: true)
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
