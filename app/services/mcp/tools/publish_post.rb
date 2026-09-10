module Mcp
  module Tools
    class PublishPost < Base
      description "Publish a blog post immediately. Sets the published_at timestamp and triggers subscriber notifications."

      input_schema(
        properties: {
          identifier: { type: "string", description: "Post slug or numeric ID" }
        },
        required: [ "identifier" ]
      )

      class << self
        def call(server_context:, identifier:)
          with_post(identifier) do |post|
            post.publish!

            success(Mcp::PostSerializer.call(post.reload))
          end
        end
      end
    end
  end
end
