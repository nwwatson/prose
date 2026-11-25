module Mcp
  module Tools
    class GetSiteInfo < Base
      description "Get information about the Prose site including name, description, categories, tags, and post counts."

      input_schema(properties: {})

      annotations(read_only_hint: true, destructive_hint: false)

      class << self
        def call(server_context:, **_params)
          success(Mcp::SiteInfo.call)
        end
      end
    end
  end
end
