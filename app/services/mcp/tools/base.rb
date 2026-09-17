module Mcp
  module Tools
    class Base < MCP::Tool
      class << self
        include Mcp::ContentLookup

        private

        def with_post(identifier)
          post = find_post(identifier)
          yield post
        rescue ActiveRecord::RecordNotFound
          failure("Post not found: #{identifier}")
        end

        def success(payload)
          MCP::Tool::Response.new([ { type: "text", text: payload.to_json } ])
        end

        def failure(message)
          MCP::Tool::Response.new([ { type: "text", text: { error: message }.to_json } ], error: true)
        end
      end
    end
  end
end
