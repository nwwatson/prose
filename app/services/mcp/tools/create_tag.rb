module Mcp
  module Tools
    class CreateTag < MCP::Tool
      description "Find or create a tag by name. Returns the existing tag if one with the same name already exists."

      input_schema(
        properties: {
          name: { type: "string", description: "Tag name" }
        },
        required: [ "name" ]
      )

      class << self
        def call(server_context:, name:)
          tag = Tag.find_or_create_by!(name: name.strip)

          result = { id: tag.id, name: tag.name, slug: tag.slug, created: tag.previously_new_record? }
          MCP::Tool::Response.new([ { type: "text", text: result.to_json } ])
        rescue ActiveRecord::RecordInvalid => e
          MCP::Tool::Response.new([ { type: "text", text: { error: e.message }.to_json } ], error: true)
        end
      end
    end
  end
end
