module Mcp
  module Tools
    class UpdatePost < MCP::Tool
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
          post = find_post(identifier)

          attrs = {}
          attrs[:title] = params[:title] if params.key?(:title)
          attrs[:subtitle] = params[:subtitle] if params.key?(:subtitle)
          attrs[:slug] = params[:slug] if params.key?(:slug)
          attrs[:meta_description] = params[:meta_description] if params.key?(:meta_description)
          attrs[:featured] = params[:featured] if params.key?(:featured)

          if params[:category].present?
            attrs[:category] = Category.find_by(name: params[:category]) || Category.find_by(slug: params[:category])
          end

          post.update!(attrs) if attrs.any?

          if params[:content].present?
            html = Mcp::MarkdownConverter.to_html(params[:content])
            post.update!(content: html)
          end

          if params.key?(:tags)
            tags = (params[:tags] || []).map { |name| Tag.find_or_create_by!(name: name.strip) }
            post.tags = tags
          end

          result = Mcp::PostSerializer.call(post.reload, include_content: true)
          MCP::Tool::Response.new([ { type: "text", text: result.to_json } ])
        rescue ActiveRecord::RecordNotFound
          MCP::Tool::Response.new([ { type: "text", text: { error: "Post not found: #{identifier}" }.to_json } ], error: true)
        rescue ActiveRecord::RecordInvalid => e
          MCP::Tool::Response.new([ { type: "text", text: { error: e.message }.to_json } ], error: true)
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
