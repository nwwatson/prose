require "test_helper"

class Mcp::Tools::GetPostTest < ActiveSupport::TestCase
  test "returns post by slug" do
    post_record = posts(:published_post)

    result = Mcp::Tools::GetPost.call(server_context: { user: users(:admin) }, identifier: post_record.slug)

    parsed = JSON.parse(result.content.first[:text])
    assert_equal post_record.title, parsed["title"]
    assert parsed.key?("content_html")
  end

  test "returns post by numeric id" do
    post_record = posts(:published_post)

    result = Mcp::Tools::GetPost.call(server_context: { user: users(:admin) }, identifier: post_record.id.to_s)

    parsed = JSON.parse(result.content.first[:text])
    assert_equal post_record.title, parsed["title"]
  end

  test "returns error for missing post" do
    result = Mcp::Tools::GetPost.call(server_context: { user: users(:admin) }, identifier: "nonexistent")

    assert result.error?
    parsed = JSON.parse(result.content.first[:text])
    assert_equal "Post not found: nonexistent", parsed["error"]
  end
end
