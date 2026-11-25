require "test_helper"

class Mcp::PostWriterTest < ActiveJob::TestCase
  include ActivityPubTestHelper

  test "create builds a draft owned by the user" do
    post = Mcp::PostWriter.create(user: users(:admin), attrs: { title: "Written", content: "**Hi**", category: "design", tags: %w[Ruby] })

    assert post.draft?
    assert_equal users(:admin), post.user
    assert_equal categories(:design), post.category
    assert_equal [ "Ruby" ], post.tags.map(&:name)
    assert_includes post.content.to_s, "<strong>Hi</strong>"
  end

  test "create ignores a requested status" do
    post = Mcp::PostWriter.create(user: users(:admin), attrs: { title: "Sneaky", status: "published" })

    assert post.draft?
  end

  test "an unknown category raises and creates nothing" do
    assert_no_difference "Post.count" do
      assert_raises(Mcp::PostWriter::UnknownCategory) do
        Mcp::PostWriter.create(user: users(:admin), attrs: { title: "Orphan", category: "no-such-category" })
      end
    end
  end

  test "update clears category and content when the keys are passed blank" do
    post = posts(:published_post)
    post.update!(content: "<p>Body</p>")

    Mcp::PostWriter.update(post: post, attrs: { category: "", content: "" })

    assert_nil post.category
    assert post.content.to_plain_text.blank?
    assert post.body_plain.blank?
  end

  test "update leaves attributes alone when their keys are absent" do
    post = posts(:published_post)
    category = post.category

    Mcp::PostWriter.update(post: post, attrs: { subtitle: "New subtitle" })

    assert_equal category, post.category
    assert_equal "New subtitle", post.subtitle
  end

  test "a failed update writes nothing, tags included" do
    post = posts(:published_post)
    tag_names = post.tags.map(&:name).sort

    assert_raises(ActiveRecord::RecordInvalid) do
      Mcp::PostWriter.update(post: post, attrs: { meta_description: "x" * 200, tags: [ "Brand New" ] })
    end

    assert_equal tag_names, post.reload.tags.map(&:name).sort
    assert_not Tag.exists?(name: "Brand New")
  end

  test "updating a published post's title and content saves once" do
    enable_federation!
    post = posts(:published_post)
    post.update!(content: "<p>Body</p>")
    clear_enqueued_jobs

    Mcp::PostWriter.update(post: post, attrs: { title: "New title", content: "New body" })

    assert_enqueued_jobs 1, only: PostUpdatedWebhookJob
    assert_equal 1, enqueued_jobs.count { |job| job[:job] == FederatePostJob && job[:args].first == "update" }
  end
end
