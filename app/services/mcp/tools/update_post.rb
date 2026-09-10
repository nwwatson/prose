module Mcp
  module Tools
    class UpdatePost < Base
      description "Update an existing blog post. Content should be provided as markdown. Only provided fields are updated."

      input_schema(
        properties: {
          identifier: { type: "string", description: "Post slug or numeric ID" },
          title: { type: "string", description: "Post title" },
          content: { type: "string", description: "Post content in markdown format" },
          subtitle: { type: "string", description: "Post subtitle" },
          slug: { type: "string", description: "URL slug" },
          category: { type: "string", description: "Category name" },
          tags: { type: "array", items: { type: "string" }, description: "Array of tag names (replaces existing)" },
          meta_description: { type: "string", description: "SEO meta description (max 160 chars)" },
          featured: { type: "boolean", description: "Whether post is featured" }
        },
        required: [ "identifier" ]
      )

      class << self
        def call(server_context:, identifier:, **params)
          with_post(identifier) do |post|
            attrs = {}
            attrs[:title] = params[:title] if params.key?(:title)
            attrs[:subtitle] = params[:subtitle] if params.key?(:subtitle)
            attrs[:slug] = params[:slug] if params.key?(:slug)
            attrs[:meta_description] = params[:meta_description] if params.key?(:meta_description)
            attrs[:featured] = params[:featured] if params.key?(:featured)

            attrs[:category] = find_category(params[:category]) if params[:category].present?

            post.update!(attrs) if attrs.any?

            if params[:content].present?
              html = Mcp::MarkdownConverter.to_html(params[:content])
              post.update!(content: html)
            end

            post.tags = find_or_create_tags(params[:tags] || []) if params.key?(:tags)

            success(Mcp::PostSerializer.call(post.reload, include_content: true))
          end
        rescue ActiveRecord::RecordInvalid => e
          failure(e.message)
        end
      end
    end
  end
end
