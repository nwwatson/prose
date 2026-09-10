module Mcp
  module Tools
    class SchedulePost < Base
      description "Schedule a blog post for future publication. Accepts an ISO 8601 datetime string."

      input_schema(
        properties: {
          identifier: { type: "string", description: "Post slug or numeric ID" },
          published_at: { type: "string", description: "ISO 8601 datetime for publication (must be in the future)" }
        },
        required: %w[identifier published_at]
      )

      class << self
        def call(server_context:, identifier:, published_at:)
          with_post(identifier) do |post|
            time = Time.iso8601(published_at)
            post.schedule!(time)

            success(Mcp::PostSerializer.call(post.reload))
          end
        rescue ArgumentError => e
          failure("Invalid datetime: #{e.message}")
        rescue ActiveRecord::RecordInvalid => e
          failure(e.message)
        end
      end
    end
  end
end
