require "test_helper"

class Post::WebhookableTest < ActiveJob::TestCase
  setup do
    @post = posts(:published_post)
    # The fixture has no rich text record yet; give it one so later saves
    # only change what each test changes.
    @post.update!(content: "<p>Body</p>")
    clear_enqueued_jobs
    travel 3.seconds
  end

  def post_updated_deliveries
    enqueued_jobs.count { |job| job[:job] == DeliverWebhookJob && job[:args][1] == "post.updated" }
  end

  test "editing a published post enqueues a delayed post.updated job" do
    freeze_time do
      @post.update!(title: "A new title")

      job = enqueued_jobs.find { |j| j[:job] == PostUpdatedWebhookJob }
      assert_equal @post.id, job[:args].first
      assert_in_delta Post::Revisable::UPDATE_DELAY.from_now.to_f, job[:at], 1
      assert_equal 0, post_updated_deliveries, "nothing is delivered until the delay elapses"
    end
  end

  test "a burst of autosaves produces one post.updated delivery" do
    [ "First", "Second", "Third" ].each do |title|
      @post.update!(title: title)
      travel 3.seconds
    end
    assert_enqueued_jobs 3, only: PostUpdatedWebhookJob

    perform_enqueued_jobs(only: PostUpdatedWebhookJob)

    assert_equal 1, post_updated_deliveries
    delivered = enqueued_jobs.find { |job| job[:job] == DeliverWebhookJob }
    assert_equal "Third", delivered[:args][2]["title"]
  end

  test "a settings-only save after an edit doesn't swallow the update" do
    @post.update!(title: "Edited")
    travel 3.seconds
    @post.update!(featured: true) # moves updated_at, not revised_at

    perform_enqueued_jobs(only: PostUpdatedWebhookJob)

    assert_equal 1, post_updated_deliveries
  end

  test "a burst that ends back at the original content still delivers once" do
    @post.update!(title: "Edited")
    travel 3.seconds
    @post.update!(title: "Published Post")

    perform_enqueued_jobs(only: PostUpdatedWebhookJob)

    assert_equal 1, post_updated_deliveries
  end

  test "saves that change nothing readers see don't enqueue post.updated" do
    assert_no_enqueued_jobs only: PostUpdatedWebhookJob do
      @post.update!(featured: true, show_toc: true)
      @post.save!
      @post.touch
    end
  end

  test "drafts never emit post.updated" do
    post = posts(:draft_post)
    post.update!(title: "Secret draft title")

    assert_no_enqueued_jobs only: PostUpdatedWebhookJob
    perform_enqueued_jobs
    assert_equal 0, post_updated_deliveries
  end

  test "status transitions stay immediate" do
    assert_enqueued_with(job: DeliverWebhookJob, args: ->(args) { args[1] == "post.unpublished" }) do
      assert_no_enqueued_jobs(only: PostUpdatedWebhookJob) { @post.revert_to_draft! }
    end
  end
end
