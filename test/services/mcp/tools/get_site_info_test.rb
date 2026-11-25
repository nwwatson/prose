require "test_helper"

class Mcp::Tools::GetSiteInfoTest < ActiveSupport::TestCase
  def call_tool
    result = Mcp::Tools::GetSiteInfo.call(server_context: { user: users(:admin) })
    JSON.parse(result.content.first[:text])
  end

  test "returns site name and description" do
    settings = SiteSetting.current
    settings.update!(site_name: "My Blog", site_description: "Words")

    parsed = call_tool

    assert_equal "My Blog", parsed["site_name"]
    assert_equal "Words", parsed["site_description"]
  end

  test "returns categories in order with post counts" do
    parsed = call_tool

    assert_equal Category.ordered.pluck(:slug), parsed["categories"].map { |c| c["slug"] }
    technology = parsed["categories"].find { |c| c["slug"] == "technology" }
    assert_equal "Technology", technology["name"]
    assert_equal categories(:technology).posts.count, technology["post_count"]
  end

  test "returns tags with post counts, zero for unused tags" do
    unused = Tag.create!(name: "Unused")

    parsed = call_tool

    assert_equal Tag.count, parsed["tags"].size
    ruby = parsed["tags"].find { |t| t["slug"] == "ruby" }
    assert_equal tags(:ruby).posts.count, ruby["post_count"]
    assert_equal 0, parsed["tags"].find { |t| t["slug"] == unused.slug }["post_count"]
  end

  test "returns post counts by status" do
    parsed = call_tool

    assert_equal(
      {
        "total" => Post.count,
        "published" => Post.published.count,
        "draft" => Post.draft.count,
        "scheduled" => Post.scheduled.count
      },
      parsed["post_counts"]
    )
    assert parsed["post_counts"]["draft"].positive?
  end

  test "is a read-only tool" do
    assert Mcp::Tools::GetSiteInfo.annotations.read_only_hint
  end
end
