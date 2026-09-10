require "test_helper"

class Mcp::Tools::UpdatePostTest < ActiveSupport::TestCase
  test "updates title and content" do
    post_record = posts(:draft_post)

    result = Mcp::Tools::UpdatePost.call(
      server_context: { user: users(:admin) },
      identifier: post_record.slug,
      title: "Updated Title",
      content: "## New content"
    )

    parsed = JSON.parse(result.content.first[:text])
    assert_equal "Updated Title", parsed["title"]
    assert_includes parsed["content_html"], "<h2>"
  end

  test "updates category by slug" do
    post_record = posts(:draft_post)

    result = Mcp::Tools::UpdatePost.call(server_context: { user: users(:admin) }, identifier: post_record.slug, category: "design")

    parsed = JSON.parse(result.content.first[:text])
    assert_equal "Design", parsed["category"]
  end

  test "replaces tags" do
    post_record = posts(:draft_post)

    result = Mcp::Tools::UpdatePost.call(server_context: { user: users(:admin) }, identifier: post_record.slug, tags: [ "New Tag" ])

    parsed = JSON.parse(result.content.first[:text])
    assert_equal [ "New Tag" ], parsed["tags"]
  end

  test "returns error for missing post" do
    result = Mcp::Tools::UpdatePost.call(server_context: { user: users(:admin) }, identifier: "nonexistent", title: "x")

    assert result.error?
    parsed = JSON.parse(result.content.first[:text])
    assert_equal "Post not found: nonexistent", parsed["error"]
  end

  test "returns error for invalid update" do
    post_record = posts(:draft_post)

    result = Mcp::Tools::UpdatePost.call(server_context: { user: users(:admin) }, identifier: post_record.slug, meta_description: "x" * 200)

    assert result.error?
    parsed = JSON.parse(result.content.first[:text])
    assert parsed["error"].present?
  end
end
