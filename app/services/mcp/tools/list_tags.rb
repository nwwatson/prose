module Mcp
  module Tools
    class ListTags < Base
      description "List all tags with their post counts."

      input_schema(properties: {})

      annotations(read_only_hint: true, destructive_hint: false)

      class << self
        def call(server_context:, **_params)
          tags = Tag.all.order(:name).map do |t|
            { id: t.id, name: t.name, slug: t.slug, post_count: t.posts.count }
          end

          success({ tags: tags })
        end
      end
    end
  end
end
