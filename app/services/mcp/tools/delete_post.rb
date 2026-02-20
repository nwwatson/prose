module Mcp
  module Tools
    class DeletePost < MCP::Tool
      description "Permanently delete a blog post by its slug or numeric ID."

      input_schema(
        properties: {
          identifier: { type: "string", description: "Post slug or numeric ID" }
        },
        required: [ "identifier" ]
      )

      annotations(destructive_hint: true)

      class << self
        def call(server_context:, identifier:)
          post = find_post(identifier)
          title = post.title
          post.destroy!

          MCP::Tool::Response.new([ { type: "text", text: { deleted: true, title: title }.to_json } ])
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
