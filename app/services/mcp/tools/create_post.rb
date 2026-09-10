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
            post.content = Mcp::MarkdownConverter.to_html(params[:content])
          end

          post.category = find_category(params[:category]) if params[:category].present?

          post.save!
          post.tags = find_or_create_tags(params[:tags]) if params[:tags].present?

          success(Mcp::PostSerializer.call(post.reload, include_content: true))
        rescue ActiveRecord::RecordInvalid => e
          failure(e.message)
        end
      end
    end
  end
end
