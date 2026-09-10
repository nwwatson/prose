require "test_helper"

class Mcp::Tools::ListCategoriesTest < ActiveSupport::TestCase
  test "lists categories with post counts" do
    result = Mcp::Tools::ListCategories.call(server_context: { user: users(:admin) })
    parsed = JSON.parse(result.content.first[:text])

    assert parsed["categories"].is_a?(Array)
    assert parsed["categories"].length >= 2

    tech = parsed["categories"].find { |c| c["name"] == "Technology" }
    assert_not_nil tech
    assert_equal categories(:technology).posts.count, tech["post_count"]
    assert_equal "technology", tech["slug"]
  end
end
