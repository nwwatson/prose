require "test_helper"

class McpFlowTest < ActionDispatch::IntegrationTest
  TOKEN = "prose_admin_test_token_1234567890abcdef"

  test "full workflow: initialize, create post, update, publish, verify" do
    # 1. Initialize
    result = mcp_call("initialize", {
      protocolVersion: "2025-03-26",
      capabilities: {},
      clientInfo: { name: "integration-test", version: "1.0" }
    })
    assert result.dig("result", "serverInfo", "name")

    # 2. List tools
    result = mcp_call("tools/list")
    tool_names = result.dig("result", "tools").map { |t| t["name"] }
    assert_includes tool_names, "create_post"
    assert_includes tool_names, "publish_post"

    # 3. Get site info
    result = mcp_call("tools/call", { name: "get_site_info", arguments: {} })
    site_info = parse_tool_result(result)
    assert site_info["site_name"].present?

    # 4. Create a draft
    result = mcp_call("tools/call", {
      name: "create_post",
      arguments: {
        title: "Integration Test Post",
        content: "# Hello World\n\nThis is a test post with **bold** and *italic* text.\n\n## Section Two\n\nA paragraph here.",
        subtitle: "Testing the full flow",
        category: "Technology",
        tags: %w[Ruby Rails],
        meta_description: "An integration test post"
      }
    })

    post_data = parse_tool_result(result)
    assert_equal "Integration Test Post", post_data["title"]
    assert_equal "draft", post_data["status"]
    slug = post_data["slug"]

    # 5. Update the post
    result = mcp_call("tools/call", {
      name: "update_post",
      arguments: {
        identifier: slug,
        content: "# Updated Content\n\nThe content has been updated.",
        featured: true
      }
    })

    updated_data = parse_tool_result(result)
    assert_includes updated_data["content_html"], "Updated Content"
    assert updated_data["featured"]

    # 6. Publish
    result = mcp_call("tools/call", {
      name: "publish_post",
      arguments: { identifier: slug }
    })

    published_data = parse_tool_result(result)
    assert_equal "published", published_data["status"]
    assert_not_nil published_data["published_at"]

    # 7. Verify in list
    result = mcp_call("tools/call", {
      name: "list_posts",
      arguments: { status: "published", search: "Integration Test" }
    })

    list_data = parse_tool_result(result)
    assert list_data["posts"].any? { |p| p["slug"] == slug }

    # 8. Get full post
    result = mcp_call("tools/call", {
      name: "get_post",
      arguments: { identifier: slug }
    })

    full_post = parse_tool_result(result)
    assert_equal "Integration Test Post", full_post["title"]
    assert full_post["content_html"].present?
  end

  private

  def mcp_call(method, params = nil)
    body = { jsonrpc: "2.0", method: method, id: SecureRandom.uuid }
    body[:params] = params if params

    post "/mcp",
      params: body.to_json,
      headers: {
        "Authorization" => "Bearer #{TOKEN}",
        "Content-Type" => "application/json"
      }

    assert_response :success
    JSON.parse(response.body)
  end

  def parse_tool_result(result)
    text = result.dig("result", "content", 0, "text")
    JSON.parse(text)
  end
end
