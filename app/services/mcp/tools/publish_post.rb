module Mcp
  module Tools
    class PublishPost < MCP::Tool
      description "Publish a blog post immediately. Sets the published_at timestamp and triggers subscriber notifications."

      input_schema(
        properties: {
          identifier: { type: "string", description: "Post slug or numeric ID" }
        },
        required: [ "identifier" ]
      )

      class << self
        def call(server_context:, identifier:)
          post = find_post(identifier)
          post.publish!

          result = Mcp::PostSerializer.call(post.reload)
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
