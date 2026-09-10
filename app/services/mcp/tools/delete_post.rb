module Mcp
  module Tools
    class DeletePost < Base
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
          with_post(identifier) do |post|
            title = post.title
            post.destroy!

            success({ deleted: true, title: title })
          end
        end
      end
    end
  end
end
