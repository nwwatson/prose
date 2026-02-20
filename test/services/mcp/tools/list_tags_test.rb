require "test_helper"

class Mcp::Tools::ListTagsTest < ActiveSupport::TestCase
  test "lists tags with post counts" do
    result = Mcp::Tools::ListTags.call(server_context: { user: users(:admin) })
    parsed = JSON.parse(result.content.first[:text])

    assert parsed["tags"].is_a?(Array)
    assert parsed["tags"].length >= 2

    ruby = parsed["tags"].find { |t| t["name"] == "Ruby" }
    assert_not_nil ruby
    assert ruby["post_count"] >= 0
  end
end
