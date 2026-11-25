require "test_helper"

class PublishScheduledPostsJobTest < ActiveJob::TestCase
  test "publishes posts past their scheduled time" do
    post = posts(:scheduled_post)
    post.update_columns(published_at: 1.minute.ago)

    PublishScheduledPostsJob.perform_now

    post.reload
    assert post.published?
    assert post.published_at.present?
  end

  test "does not publish future scheduled posts" do
    post = posts(:scheduled_post)

    PublishScheduledPostsJob.perform_now

    post.reload
    assert post.scheduled?
  end

  test "does not affect drafts" do
    post = posts(:draft_post)

    PublishScheduledPostsJob.perform_now

    post.reload
    assert post.draft?
  end

  test "a post that fails to publish is reported and does not block later posts" do
    other = Post.create!(title: "Also due", user: posts(:scheduled_post).user, status: :scheduled, published_at: 1.day.from_now)
    # find_each runs in id order, so break the post that comes first.
    failing, later = [ posts(:scheduled_post), other ].sort_by(&:id)
    failing.update_columns(title: "", published_at: 1.minute.ago)
    later.update_columns(published_at: 1.minute.ago)

    assert_error_reported(ActiveRecord::RecordInvalid) do
      PublishScheduledPostsJob.perform_now
    end

    assert failing.reload.scheduled?
    assert later.reload.published?
  end
end
