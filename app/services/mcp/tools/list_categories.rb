module Mcp
  module Tools
    class ListCategories < Base
      description "List all categories with their post counts."

      input_schema(properties: {})

      annotations(read_only_hint: true, destructive_hint: false)

      class << self
        def call(server_context:, **_params)
          success({ categories: Mcp::CategorySerializer.all })
        end
      end
    end
  end
end
