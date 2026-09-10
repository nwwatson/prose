module Mcp
  module Tools
    class UnpublishPost < Base
      description "Revert a published or scheduled post back to draft status."

      input_schema(
        properties: {
          identifier: { type: "string", description: "Post slug or numeric ID" }
        },
        required: [ "identifier" ]
      )

      class << self
        def call(server_context:, identifier:)
          with_post(identifier) do |post|
            post.revert_to_draft!

            success(Mcp::PostSerializer.call(post.reload))
          end
        end
      end
    end
  end
end
