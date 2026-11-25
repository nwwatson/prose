require "test_helper"

class PostUpdatedWebhookJobTest < ActiveJob::TestCase
  setup do
    @post = posts(:published_post)
    @post.update_column(:revised_at, Time.current)
  end

  test "delivers post.updated for the latest revision" do
    assert_enqueued_with(job: DeliverWebhookJob, args: ->(args) { args[1] == "post.updated" && args[2][:id] == @post.id }) do
      PostUpdatedWebhookJob.perform_now(@post.id, @post.revised_at.to_f)
    end
  end

  test "skips a superseded revision" do
    assert_no_enqueued_jobs only: DeliverWebhookJob do
      PostUpdatedWebhookJob.perform_now(@post.id, 1.minute.ago.to_f)
    end
  end

  test "skips a post that was unpublished or deleted during the delay" do
    revision = @post.revised_at.to_f
    @post.update_columns(status: Post.statuses[:draft])

    assert_no_enqueued_jobs only: DeliverWebhookJob do
      PostUpdatedWebhookJob.perform_now(@post.id, revision)
      PostUpdatedWebhookJob.perform_now(0, revision)
    end
  end
end
