module Mcp
  module Tools
    class GetPost < Base
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
          with_post(identifier) do |post|
            success(Mcp::PostSerializer.call(post, include_content: true))
          end
        end
      end
    end
  end
end
