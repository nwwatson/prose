module Mcp
  module Tools
    class CreatePost < Base
      description "Create a new blog post as a draft. Content should be provided as markdown, which will be converted to HTML."

      input_schema(
        properties: {
          title: { type: "string", description: "Post title" },
          content: { type: "string", description: "Post content in markdown format" },
          subtitle: { type: "string", description: "Post subtitle" },
          slug: { type: "string", description: "URL slug (auto-generated from title if omitted)" },
          category: { type: "string", description: "Category name or slug (must already exist)" },
          tags: { type: "array", items: { type: "string" }, description: "Array of tag names" },
          meta_description: { type: "string", description: "SEO meta description (max 160 chars)" },
          featured: { type: "boolean", description: "Whether post is featured" }
        },
        required: [ "title" ]
      )

      annotations(destructive_hint: false)

      class << self
        def call(server_context:, title:, **params)
          post = Mcp::PostWriter.create(user: server_context[:user], attrs: params.merge(title: title))

          success(Mcp::PostSerializer.call(post, include_content: true))
        rescue Mcp::PostWriter::UnknownCategory, ActiveRecord::RecordInvalid => e
          failure(e.message)
        end
      end
    end
  end
end
