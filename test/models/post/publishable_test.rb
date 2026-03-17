require "test_helper"

class Post::PublishableTest < ActiveSupport::TestCase
  test "publish! sets status to published with timestamp" do
    post = posts(:draft_post)
    post.publish!
    assert post.published?
    assert post.published_at.present?
  end

  test "revert_to_draft! clears published state" do
    post = posts(:published_post)
    post.revert_to_draft!
    assert post.draft?
    assert_nil post.published_at
  end

  test "live scope returns published and past-due scheduled posts" do
    past_due = posts(:scheduled_post)
    past_due.update_columns(published_at: 1.minute.ago)

    live = Post.live
    assert_includes live, posts(:published_post)
    assert_includes live, past_due
    assert_not_includes live, posts(:draft_post)
  end

  test "live scope excludes future scheduled posts" do
    assert_not_includes Post.live, posts(:scheduled_post)
  end

  test "ready_to_publish scope returns scheduled posts past their time" do
    post = posts(:scheduled_post)
    post.update_columns(published_at: 1.minute.ago)

    ready = Post.ready_to_publish
    assert_includes ready, post
  end

  test "ready_to_publish excludes future scheduled posts" do
    assert_not_includes Post.ready_to_publish, posts(:scheduled_post)
  end
end
