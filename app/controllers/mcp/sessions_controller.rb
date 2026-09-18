module Mcp
  class SessionsController < ActionController::API
    # Declared before the token check so unauthenticated requests are throttled too.
    rate_limit to: 60, within: 1.minute

    include Api::TokenAuthenticatable

    # The transport reads and parses the raw body itself (returning a JSON-RPC parse
    # error for bad JSON), so keep Rails from parsing it into params first.
    wrap_parameters false

    # upload_asset and set_featured_image take base64 files, which inflate by a third;
    # the transport's 4 MiB default would reject images over ~3 MB.
    MAX_REQUEST_BYTES = 16.megabytes

    # Serves POST, GET and DELETE /mcp through the SDK's Streamable HTTP transport, which
    # handles the HTTP side of the spec that clients such as Claude Desktop (via
    # mcp-remote) and Claude Code rely on: 202 for notifications, 405 for the optional
    # GET event stream, Accept/Content-Type checks and the MCP-Protocol-Version header.
    def handle
      status, headers, body = transport.handle_request(request)

      response.headers.merge!(headers)
      self.status = status
      self.response_body = body.respond_to?(:each) ? body.to_enum(:each).to_a.join : body.to_s
    end

    private

    # Stateless, JSON-response mode: each request is self-contained, so nothing is kept
    # in memory between requests (Puma workers don't share state) and responses are
    # plain JSON instead of an SSE stream. Host checking is left to Rails'
    # `config.hosts`, and every request must carry a bearer token anyway.
    def transport
      MCP::Server::Transports::StreamableHTTPTransport.new(
        mcp_server,
        stateless: true,
        enable_json_response: true,
        serve_subscriptions_listen: false,
        dns_rebinding_protection: false,
        max_request_bytes: MAX_REQUEST_BYTES
      )
    end

    def mcp_server
      MCP::Server.new(
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
    end

    def render_unauthorized(message)
      render json: { jsonrpc: "2.0", error: { code: -32001, message: message }, id: nil }, status: :unauthorized
    end
  end
end
