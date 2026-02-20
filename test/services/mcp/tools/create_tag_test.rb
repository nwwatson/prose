require "test_helper"

class Mcp::Tools::CreateTagTest < ActiveSupport::TestCase
  test "creates a new tag" do
    assert_difference "Tag.count", 1 do
      result = Mcp::Tools::CreateTag.call(
        server_context: { user: users(:admin) },
        name: "New Tag"
      )

      parsed = JSON.parse(result.content.first[:text])
      assert_equal "New Tag", parsed["name"]
      assert parsed["slug"].present?
    end
  end

  test "returns existing tag if name matches" do
    assert_no_difference "Tag.count" do
      result = Mcp::Tools::CreateTag.call(
        server_context: { user: users(:admin) },
        name: "Ruby"
      )

      parsed = JSON.parse(result.content.first[:text])
      assert_equal "Ruby", parsed["name"]
    end
  end
end
