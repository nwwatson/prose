# Bearer tokens matching test/fixtures/api_tokens.yml, plus REST and MCP request helpers.
module ApiHelper
  ADMIN_API_TOKEN = "prose_admin_test_token_1234567890abcdef".freeze
  WRITER_API_TOKEN = "prose_writer_test_token_1234567890abcdef".freeze
  REVOKED_API_TOKEN = "prose_revoked_test_token_1234567890abcdef".freeze

  # What Streamable HTTP clients (Claude Desktop via mcp-remote, Claude Code) send.
  MCP_HEADERS = { "Content-Type" => "application/json", "Accept" => "application/json, text/event-stream" }.freeze

  def api_auth_header(token = ADMIN_API_TOKEN)
    { "Authorization" => "Bearer #{token}" }
  end

  def mcp_headers(token = ADMIN_API_TOKEN)
    MCP_HEADERS.merge(api_auth_header(token))
  end

  def mcp_request(method, params = nil, id: 1)
    req = { jsonrpc: "2.0", method: method, id: id }
    req[:params] = params if params
    req.to_json
  end

  def mcp_call(method, params = nil, token: ADMIN_API_TOKEN)
    post "/mcp", params: mcp_request(method, params), headers: mcp_headers(token)

    assert_response :success
    JSON.parse(response.body)
  end

  def parse_tool_result(result)
    JSON.parse(result.dig("result", "content", 0, "text"))
  end
end
