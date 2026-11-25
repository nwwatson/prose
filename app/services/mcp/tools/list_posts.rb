module Mcp
  module Tools
    class ListPosts < Base
      description "List blog posts with optional filters for status, category, tag, and search query. Returns paginated results."

      input_schema(
        properties: {
          status: { type: "string", enum: %w[draft scheduled published], description: "Filter by post status" },
          category: { type: "string", description: "Filter by category name or slug (an unknown category returns no posts)" },
          tag: { type: "string", description: "Filter by tag name or slug (an unknown tag returns no posts)" },
          search: { type: "string", description: "Search posts by title, subtitle, or body content" },
          page: { type: "integer", description: "Page number (default: 1)", minimum: 1 },
          per_page: { type: "integer", description: "Results per page (default: 20, max: 50)", minimum: 1, maximum: 50 }
        }
      )

      annotations(read_only_hint: true, destructive_hint: false)

      class << self
        def call(server_context:, **params)
          result = Mcp::PostListQuery.call(params)

          success({
            posts: result.posts.map { |post| Mcp::PostSerializer.call(post) },
            total: result.total,
            page: result.page,
            per_page: result.per_page
          })
        end
      end
    end
  end
end
