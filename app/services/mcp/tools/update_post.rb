module Mcp
  module Tools
    class UpdatePost < Base
      description "Update an existing blog post. Content should be provided as markdown. Only provided fields are updated."

      input_schema(
        properties: {
          identifier: { type: "string", description: "Post slug or numeric ID" },
          title: { type: "string", description: "Post title" },
          content: { type: "string", description: "Post content in markdown format (empty string clears it)" },
          subtitle: { type: "string", description: "Post subtitle" },
          slug: { type: "string", description: "URL slug" },
          category: { type: "string", description: "Category name or slug (must already exist; empty string clears it)" },
          tags: { type: "array", items: { type: "string" }, description: "Array of tag names (replaces existing)" },
          meta_description: { type: "string", description: "SEO meta description (max 160 chars)" },
          featured: { type: "boolean", description: "Whether post is featured" }
        },
        required: [ "identifier" ]
      )

      class << self
        def call(server_context:, identifier:, **params)
          with_post(identifier) do |post|
            post = Mcp::PostWriter.update(post: post, attrs: params)

            success(Mcp::PostSerializer.call(post, include_content: true))
          end
        rescue Mcp::PostWriter::UnknownCategory, ActiveRecord::RecordInvalid => e
          failure(e.message)
        end
      end
    end
  end
end
