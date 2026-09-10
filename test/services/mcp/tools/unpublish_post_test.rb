require "test_helper"

class Mcp::Tools::UnpublishPostTest < ActiveSupport::TestCase
  test "reverts published post to draft" do
    post_record = posts(:published_post)

    result = Mcp::Tools::UnpublishPost.call(server_context: { user: users(:admin) }, identifier: post_record.slug)

    parsed = JSON.parse(result.content.first[:text])
    assert_equal "draft", parsed["status"]
    assert_nil parsed["published_at"]
  end

  test "returns error for missing post" do
    result = Mcp::Tools::UnpublishPost.call(server_context: { user: users(:admin) }, identifier: "nonexistent")

    assert result.error?
    parsed = JSON.parse(result.content.first[:text])
    assert_equal "Post not found: nonexistent", parsed["error"]
  end
end
