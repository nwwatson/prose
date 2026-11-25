module Mcp
  # Site metadata, categories, tags and post counts — the payload of both the
  # `get_site_info` MCP tool and `GET /api/v1/site`.
  class SiteInfo
    def self.call
      settings = SiteSetting.current

      {
        site_name: settings.site_name,
        site_description: settings.site_description,
        categories: Mcp::CategorySerializer.all(detailed: false),
        tags: Mcp::TagSerializer.all(detailed: false),
        post_counts: {
          total: Post.count,
          published: Post.published.count,
          draft: Post.draft.count,
          scheduled: Post.scheduled.count
        }
      }
    end
  end
end
