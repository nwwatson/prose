module Mcp
  module Tools
    class GetPost < MCP::Tool
      description "Get a single blog post by its slug or numeric ID. Returns full content."

      input_schema(
        properties: {
          identifier: { type: "string", description: "Post slug or numeric ID" }
        },
        required: [ "identifier" ]
      )

      annotations(read_only_hint: true, destructive_hint: false)

      class << self
        def call(server_context:, identifier:)
          post = find_post(identifier)
          result = Mcp::PostSerializer.call(post, include_content: true)

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
