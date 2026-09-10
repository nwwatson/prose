require "test_helper"

class Mcp::Tools::SchedulePostTest < ActiveSupport::TestCase
  test "schedules a post for future publication" do
    post_record = posts(:draft_post)
    future = 1.week.from_now.iso8601

    result = Mcp::Tools::SchedulePost.call(server_context: { user: users(:admin) }, identifier: post_record.slug, published_at: future)

    parsed = JSON.parse(result.content.first[:text])
    assert_equal "scheduled", parsed["status"]
  end

  test "returns error for missing post" do
    result = Mcp::Tools::SchedulePost.call(server_context: { user: users(:admin) }, identifier: "nonexistent", published_at: 1.week.from_now.iso8601)

    assert result.error?
    parsed = JSON.parse(result.content.first[:text])
    assert_equal "Post not found: nonexistent", parsed["error"]
  end

  test "returns error for invalid datetime" do
    post_record = posts(:draft_post)

    result = Mcp::Tools::SchedulePost.call(server_context: { user: users(:admin) }, identifier: post_record.slug, published_at: "not-a-date")

    assert result.error?
    parsed = JSON.parse(result.content.first[:text])
    assert_match(/Invalid datetime/, parsed["error"])
  end

  test "returns error for past datetime" do
    post_record = posts(:draft_post)

    result = Mcp::Tools::SchedulePost.call(server_context: { user: users(:admin) }, identifier: post_record.slug, published_at: 1.day.ago.iso8601)

    assert result.error?
    parsed = JSON.parse(result.content.first[:text])
    assert parsed["error"].present?
  end
end
