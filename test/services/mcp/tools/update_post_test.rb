require "test_helper"

class Mcp::Tools::UpdatePostTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include ActivityPubTestHelper
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

  test "returns an error for an unknown category and leaves the post unchanged" do
    post_record = posts(:published_post)

    result = Mcp::Tools::UpdatePost.call(server_context: { user: users(:admin) }, identifier: post_record.slug, title: "Changed", category: "no-such-category")

    assert result.error?
    assert_equal "Category not found: no-such-category", JSON.parse(result.content.first[:text])["error"]
    assert_equal "Published Post", post_record.reload.title
  end

  test "clears the category and content when passed blank" do
    post_record = posts(:published_post)
    post_record.update!(content: "<p>Body</p>")

    result = Mcp::Tools::UpdatePost.call(server_context: { user: users(:admin) }, identifier: post_record.slug, category: "", content: "")

    parsed = JSON.parse(result.content.first[:text])
    assert_nil parsed["category"]
    assert parsed["content_plain"].blank?
  end

  test "editing a published post saves once, so post.updated and the fediverse Update fire once" do
    enable_federation!
    post_record = posts(:published_post)
    post_record.update!(content: "<p>Body</p>")
    clear_enqueued_jobs
    # No freeze/travel: two saves in one frozen instant stamp the same
    # revised_at, which would hide a second save.

    Mcp::Tools::UpdatePost.call(server_context: { user: users(:admin) }, identifier: post_record.slug, title: "New title", content: "New body")

    assert_enqueued_jobs 1, only: PostUpdatedWebhookJob
    assert_equal 1, enqueued_jobs.count { |job| job[:job] == FederatePostJob && job[:args].first == "update" }
  end
end
