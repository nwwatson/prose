module Mcp
  # Site metadata, categories, tags and post counts — the payload of both the
  # `get_site_info` MCP tool and `GET /api/v1/site`.
  class SiteInfo
    def self.call
      settings = SiteSetting.current
      posts_by_status = Post.group(:status).count

      {
        site_name: settings.site_name,
        site_description: settings.site_description,
        categories: Mcp::CategorySerializer.all(detailed: false),
        tags: Mcp::TagSerializer.all(detailed: false),
        post_counts: {
          total: posts_by_status.values.sum,
          published: posts_by_status.fetch("published", 0),
          draft: posts_by_status.fetch("draft", 0),
          scheduled: posts_by_status.fetch("scheduled", 0)
        }
      }
    end
  end
end
