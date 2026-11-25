module Mcp
  module Tools
    class ListTags < Base
      description "List all tags with their post counts."

      input_schema(properties: {})

      annotations(read_only_hint: true, destructive_hint: false)

      class << self
        def call(server_context:, **_params)
          success({ tags: Mcp::TagSerializer.all })
        end
      end
    end
  end
end
