require "test_helper"

class PublishScheduledPostsJobTest < ActiveJob::TestCase
  test "publishes posts past their scheduled time" do
    post = posts(:scheduled_post)
    post.update_columns(scheduled_at: 1.minute.ago)

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
end
