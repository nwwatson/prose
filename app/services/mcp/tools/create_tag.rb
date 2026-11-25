module Mcp
  module Tools
    class CreateTag < Base
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

          success(Mcp::TagSerializer.call(tag).merge(created: tag.previously_new_record?))
        rescue ActiveRecord::RecordInvalid => e
          failure(e.message)
        end
      end
    end
  end
end
