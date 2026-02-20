module Mcp
  module Tools
    class ListPosts < MCP::Tool
      description "List blog posts with optional filters for status, category, tag, and search query. Returns paginated results."

      input_schema(
        properties: {
          status: { type: "string", enum: %w[draft scheduled published], description: "Filter by post status" },
          category: { type: "string", description: "Filter by category name" },
          tag: { type: "string", description: "Filter by tag name" },
          search: { type: "string", description: "Search posts by title or subtitle" },
          page: { type: "integer", description: "Page number (default: 1)", minimum: 1 },
          per_page: { type: "integer", description: "Results per page (default: 20, max: 50)", minimum: 1, maximum: 50 }
        }
      )

      annotations(read_only_hint: true, destructive_hint: false)

      class << self
        def call(server_context:, **params)
          posts = Post.includes(:user, :category, :tags)

          posts = posts.where(status: params[:status]) if params[:status].present?

          if params[:category].present?
            category = Category.find_by(name: params[:category]) || Category.find_by(slug: params[:category])
            posts = posts.where(category: category) if category
          end

          if params[:tag].present?
            tag = Tag.find_by(name: params[:tag]) || Tag.find_by(slug: params[:tag])
            posts = posts.joins(:tags).where(tags: { id: tag&.id }) if tag
          end

          posts = posts.search(params[:search]) if params[:search].present?

          per_page = [ params[:per_page] || 20, 50 ].min
          page = params[:page] || 1
          offset = (page - 1) * per_page

          total = posts.count
          posts = posts.order(created_at: :desc).limit(per_page).offset(offset)

          result = {
            posts: posts.map { |p| Mcp::PostSerializer.call(p) },
            total: total,
            page: page,
            per_page: per_page
          }

          MCP::Tool::Response.new([ { type: "text", text: result.to_json } ])
        end
      end
    end
  end
end
