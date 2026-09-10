require "test_helper"

class Mcp::Tools::ListPostsTest < ActiveSupport::TestCase
  test "lists posts" do
    result = Mcp::Tools::ListPosts.call(server_context: { user: users(:admin) })

    parsed = JSON.parse(result.content.first[:text])
    assert parsed["posts"].is_a?(Array)
    assert parsed["total"] > 0
  end

  test "filters by status" do
    result = Mcp::Tools::ListPosts.call(server_context: { user: users(:admin) }, status: "draft")

    parsed = JSON.parse(result.content.first[:text])
    parsed["posts"].each { |p| assert_equal "draft", p["status"] }
  end

  test "filters by category" do
    result = Mcp::Tools::ListPosts.call(server_context: { user: users(:admin) }, category: "design")

    parsed = JSON.parse(result.content.first[:text])
    assert parsed["posts"].any?
    parsed["posts"].each { |p| assert_equal "Design", p["category"] }
  end

  test "paginates results" do
    result = Mcp::Tools::ListPosts.call(server_context: { user: users(:admin) }, page: 1, per_page: 2)

    parsed = JSON.parse(result.content.first[:text])
    assert_equal 2, parsed["per_page"]
    assert parsed["posts"].length <= 2
  end
end
