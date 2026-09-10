module Mcp
  module Tools
    class ListCategories < Base
      description "List all categories with their post counts."

      input_schema(properties: {})

      annotations(read_only_hint: true, destructive_hint: false)

      class << self
        def call(server_context:, **_params)
          categories = Category.ordered.map do |c|
            { id: c.id, name: c.name, slug: c.slug, description: c.description, position: c.position, post_count: c.posts.count }
          end

          success({ categories: categories })
        end
      end
    end
  end
end
