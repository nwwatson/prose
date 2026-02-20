module Mcp
  module Tools
    class CreatePost < MCP::Tool
      description "Create a new blog post as a draft. Content should be provided as markdown, which will be converted to HTML."

      input_schema(
        properties: {
          title: { type: "string", description: "Post title" },
          content: { type: "string", description: "Post content in markdown format" },
          subtitle: { type: "string", description: "Post subtitle" },
          slug: { type: "string", description: "URL slug (auto-generated from title if omitted)" },
          category: { type: "string", description: "Category name" },
          tags: { type: "array", items: { type: "string" }, description: "Array of tag names" },
          meta_description: { type: "string", description: "SEO meta description (max 160 chars)" }
        },
        required: [ "title" ]
      )

      annotations(destructive_hint: false)

      class << self
        def call(server_context:, title:, **params)
          user = server_context[:user]

          post = Post.new(
            title: title,
            subtitle: params[:subtitle],
            slug: params[:slug],
            meta_description: params[:meta_description],
            user: user,
            status: :draft
          )

          if params[:content].present?
            html = Mcp::MarkdownConverter.to_html(params[:content])
            post.content = html
          end

          if params[:category].present?
            post.category = Category.find_by(name: params[:category]) || Category.find_by(slug: params[:category])
          end

          post.save!
          assign_tags(post, params[:tags]) if params[:tags].present?

          result = Mcp::PostSerializer.call(post.reload, include_content: true)
          MCP::Tool::Response.new([ { type: "text", text: result.to_json } ])
        rescue ActiveRecord::RecordInvalid => e
          MCP::Tool::Response.new([ { type: "text", text: { error: e.message }.to_json } ], error: true)
        end

        private

        def assign_tags(post, tag_names)
          tags = tag_names.map { |name| Tag.find_or_create_by!(name: name.strip) }
          post.tags = tags
        end
      end
    end
  end
end
