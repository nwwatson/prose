module Mcp
  module Tools
    class GetSiteInfo < MCP::Tool
      description "Get information about the Prose site including name, description, categories, tags, and post counts."

      input_schema(properties: {})

      annotations(read_only_hint: true, destructive_hint: false)

      class << self
        def call(server_context:, **_params)
          settings = SiteSetting.current

          result = {
            site_name: settings.site_name,
            site_description: settings.site_description,
            categories: Category.ordered.map { |c| { name: c.name, slug: c.slug, post_count: c.posts.count } },
            tags: Tag.all.map { |t| { name: t.name, slug: t.slug, post_count: t.posts.count } },
            post_counts: {
              total: Post.count,
              published: Post.published.count,
              draft: Post.draft.count,
              scheduled: Post.scheduled.count
            }
          }

          MCP::Tool::Response.new([ { type: "text", text: result.to_json } ])
        end
      end
    end
  end
end
