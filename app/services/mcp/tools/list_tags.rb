module Mcp
  module Tools
    class ListTags < MCP::Tool
      description "List all tags with their post counts."

      input_schema(properties: {})

      annotations(read_only_hint: true, destructive_hint: false)

      class << self
        def call(server_context:, **_params)
          tags = Tag.all.order(:name).map do |t|
            { id: t.id, name: t.name, slug: t.slug, post_count: t.posts.count }
          end

          MCP::Tool::Response.new([ { type: "text", text: { tags: tags }.to_json } ])
        end
      end
    end
  end
end
