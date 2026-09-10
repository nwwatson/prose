require "test_helper"

class Mcp::Tools::PublishPostTest < ActiveSupport::TestCase
  test "publishes a draft post" do
    post_record = posts(:draft_post)

    result = Mcp::Tools::PublishPost.call(server_context: { user: users(:admin) }, identifier: post_record.slug)

    parsed = JSON.parse(result.content.first[:text])
    assert_equal "published", parsed["status"]
    assert_not_nil parsed["published_at"]
  end

  test "returns error for missing post" do
    result = Mcp::Tools::PublishPost.call(server_context: { user: users(:admin) }, identifier: "nonexistent")

    assert result.error?
    parsed = JSON.parse(result.content.first[:text])
    assert_equal "Post not found: nonexistent", parsed["error"]
  end
end
