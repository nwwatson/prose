require "test_helper"

class Mcp::Tools::DeletePostTest < ActiveSupport::TestCase
  test "deletes post by slug" do
    post_record = posts(:draft_post)

    result = Mcp::Tools::DeletePost.call(server_context: { user: users(:admin) }, identifier: post_record.slug)

    parsed = JSON.parse(result.content.first[:text])
    assert parsed["deleted"]
    assert_equal post_record.title, parsed["title"]
    assert_raises(ActiveRecord::RecordNotFound) { post_record.reload }
  end

  test "deletes post by numeric id" do
    post_record = posts(:draft_post)

    result = Mcp::Tools::DeletePost.call(server_context: { user: users(:admin) }, identifier: post_record.id.to_s)

    parsed = JSON.parse(result.content.first[:text])
    assert parsed["deleted"]
  end

  test "returns error for missing post" do
    result = Mcp::Tools::DeletePost.call(server_context: { user: users(:admin) }, identifier: "nonexistent")

    assert result.error?
    parsed = JSON.parse(result.content.first[:text])
    assert_equal "Post not found: nonexistent", parsed["error"]
  end
end
