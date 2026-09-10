module Mcp
  class SessionsController < ActionController::API
    include Api::TokenAuthenticatable

    rate_limit to: 60, within: 1.minute

    def create
      server = MCP::Server.new(
        name: "prose",
        title: "Prose Blog",
        version: "1.0.0",
        instructions: "Manage blog posts, categories, tags, and assets on a Prose blog.",
        tools: Mcp::ToolRegistry.all,
        server_context: { user: Current.user },
        configuration: MCP::Configuration.new(
          exception_reporter: ->(exception, _context) {
            Rails.logger.error("[MCP] #{exception.class}: #{exception.message}")
          }
        )
      )

      response_json = server.handle_json(request.body.read)
      render json: response_json
    rescue JSON::ParserError
      render json: {
        jsonrpc: "2.0",
        error: { code: -32700, message: "Parse error" },
        id: nil
      }
    rescue StandardError => e
      Rails.logger.error("[MCP] Unhandled error: #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
      render json: {
        jsonrpc: "2.0",
        error: { code: -32000, message: "Internal server error" },
        id: nil
      }
    end

    private

    def render_unauthorized(message)
      render json: { jsonrpc: "2.0", error: { code: -32001, message: message }, id: nil }, status: :unauthorized
    end
  end
end
