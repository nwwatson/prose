require "test_helper"

class Mcp::SessionsControllerTest < ActionDispatch::IntegrationTest
  VALID_TOKEN = "prose_admin_test_token_1234567890abcdef"
  WRITER_TOKEN = "prose_writer_test_token_1234567890abcdef"
  REVOKED_TOKEN = "prose_revoked_test_token_1234567890abcdef"

  # --- Auth tests ---

  test "rejects request without Authorization header" do
    post "/mcp", params: mcp_request("initialize"), as: :json
    assert_response :unauthorized
    body = JSON.parse(response.body)
    assert_equal(-32001, body.dig("error", "code"))
  end

  test "rejects invalid token" do
    post "/mcp", params: mcp_request("initialize"), headers: auth_header("prose_invalid"), as: :json
    assert_response :unauthorized
  end

  test "rejects revoked token" do
    post "/mcp", params: mcp_request("initialize"), headers: auth_header(REVOKED_TOKEN), as: :json
    assert_response :unauthorized
  end

  test "accepts valid token and updates last_used" do
    token = api_tokens(:admin_token)
    assert_nil token.last_used_at

    post "/mcp", params: mcp_request("initialize"), headers: auth_header(VALID_TOKEN), as: :json
    assert_response :success

    token.reload
    assert_not_nil token.last_used_at
  end

  # --- MCP protocol tests ---

  test "initialize returns server info" do
    result = mcp_call("initialize", {
      protocolVersion: "2025-03-26",
      capabilities: {},
      clientInfo: { name: "test", version: "1.0" }
    })

    assert result["result"]
    assert_equal "prose", result.dig("result", "serverInfo", "name")
  end

  test "tools/list returns available tools" do
    result = mcp_call("tools/list")

    tools = result.dig("result", "tools")
    assert_instance_of Array, tools
    assert tools.length >= 9

    tool_names = tools.map { |t| t["name"] }
    assert_includes tool_names, "list_posts"
    assert_includes tool_names, "create_post"
    assert_includes tool_names, "get_site_info"
  end

  # --- Tool: list_posts ---

  test "list_posts returns posts" do
    result = call_tool("list_posts", {})
    data = parse_tool_result(result)

    assert data["posts"].is_a?(Array)
    assert data["total"] > 0
  end

  test "list_posts filters by status" do
    result = call_tool("list_posts", { status: "draft" })
    data = parse_tool_result(result)

    data["posts"].each do |p|
      assert_equal "draft", p["status"]
    end
  end

  # --- Tool: get_post ---

  test "get_post by slug" do
    result = call_tool("get_post", { identifier: "published-post" })
    data = parse_tool_result(result)

    assert_equal "Published Post", data["title"]
    assert data.key?("content_html")
  end

  test "get_post by id" do
    post_record = posts(:published_post)
    result = call_tool("get_post", { identifier: post_record.id.to_s })
    data = parse_tool_result(result)

    assert_equal "Published Post", data["title"]
  end

  test "get_post returns error for missing post" do
    result = call_tool("get_post", { identifier: "nonexistent-slug" })
    data = parse_tool_result(result)

    assert data["error"]
  end

  # --- Tool: create_post ---

  test "create_post creates a draft with markdown content" do
    result = call_tool("create_post", {
      title: "My New Post",
      content: "# Hello\n\nThis is **bold** text.",
      subtitle: "A subtitle",
      category: "Technology",
      tags: %w[Ruby Rails]
    })

    data = parse_tool_result(result)
    assert_equal "My New Post", data["title"]
    assert_equal "draft", data["status"]
    assert_equal "Technology", data["category"]
    assert_includes data["content_html"], "<h1>"
    assert_includes data["content_html"], "<strong>bold</strong>"

    post_record = Post.find(data["id"])
    assert_equal users(:admin), post_record.user
  end

  # --- Tool: update_post ---

  test "update_post updates title and content" do
    post_record = posts(:draft_post)
    result = call_tool("update_post", {
      identifier: post_record.slug,
      title: "Updated Title",
      content: "## New content"
    }, token: WRITER_TOKEN)

    data = parse_tool_result(result)
    assert_equal "Updated Title", data["title"]
    assert_includes data["content_html"], "<h2>"
  end

  # --- Tool: delete_post ---

  test "delete_post removes post" do
    post_record = posts(:draft_post)
    result = call_tool("delete_post", { identifier: post_record.slug }, token: WRITER_TOKEN)
    data = parse_tool_result(result)

    assert data["deleted"]
    assert_raises(ActiveRecord::RecordNotFound) { post_record.reload }
  end

  # --- Tool: publish_post ---

  test "publish_post publishes a draft" do
    post_record = posts(:draft_post)
    result = call_tool("publish_post", { identifier: post_record.slug }, token: WRITER_TOKEN)
    data = parse_tool_result(result)

    assert_equal "published", data["status"]
    assert_not_nil data["published_at"]
  end

  # --- Tool: schedule_post ---

  test "schedule_post schedules a post" do
    post_record = posts(:draft_post)
    future = 1.week.from_now.iso8601
    result = call_tool("schedule_post", {
      identifier: post_record.slug,
      scheduled_at: future
    }, token: WRITER_TOKEN)

    data = parse_tool_result(result)
    assert_equal "scheduled", data["status"]
  end

  # --- Tool: unpublish_post ---

  test "unpublish_post reverts to draft" do
    post_record = posts(:published_post)
    result = call_tool("unpublish_post", { identifier: post_record.slug })
    data = parse_tool_result(result)

    assert_equal "draft", data["status"]
    assert_nil data["published_at"]
  end

  # --- Tool: get_site_info ---

  test "get_site_info returns site information" do
    result = call_tool("get_site_info", {})
    data = parse_tool_result(result)

    assert data["site_name"].present?
    assert data["categories"].is_a?(Array)
    assert data["tags"].is_a?(Array)
    assert data["post_counts"].is_a?(Hash)
  end

  private

  def auth_header(token)
    { "Authorization" => "Bearer #{token}" }
  end

  def mcp_request(method, params = nil, id: 1)
    req = { jsonrpc: "2.0", method: method, id: id }
    req[:params] = params if params
    req.to_json
  end

  def mcp_call(method, params = nil, token: VALID_TOKEN)
    post "/mcp",
      params: mcp_request(method, params),
      headers: auth_header(token).merge("Content-Type" => "application/json")

    assert_response :success
    JSON.parse(response.body)
  end

  def call_tool(name, arguments, token: VALID_TOKEN)
    # First initialize
    mcp_call("initialize", {
      protocolVersion: "2025-03-26",
      capabilities: {},
      clientInfo: { name: "test", version: "1.0" }
    }, token: token)

    # Then call tool
    mcp_call("tools/call", { name: name, arguments: arguments }, token: token)
  end

  def parse_tool_result(result)
    text = result.dig("result", "content", 0, "text")
    JSON.parse(text)
  end
end
