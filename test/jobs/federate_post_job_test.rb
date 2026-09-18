require "test_helper"

class FederatePostJobTest < ActiveJob::TestCase
  include ActivityPubTestHelper

  setup do
    enable_federation!
    remote_actor.follow!
    @post = posts(:published_post)
  end

  test "fans a Create out to each follower inbox" do
    FederatePostJob.perform_now("create", @post.id, ActivityPub::Urls.post_url(@post))

    assert_enqueued_jobs 1, only: DeliverActivityJob
    inbox, body = enqueued_jobs.last[:args]
    assert_equal "https://remote.example/inbox", inbox
    assert_equal "Create", JSON.parse(body)["type"]
  end

  test "Delete works after the post is gone" do
    url = ActivityPub::Urls.post_url(@post)
    @post.destroy!
    clear_enqueued_jobs

    FederatePostJob.perform_now("delete", @post.id, url)

    assert_equal "Delete", JSON.parse(enqueued_jobs.last[:args].last)["type"]
  end

  test "a superseded update is skipped" do
    FederatePostJob.perform_now("update", @post.id, ActivityPub::Urls.post_url(@post), (@post.updated_at - 1.minute).to_f)
    assert_no_enqueued_jobs only: DeliverActivityJob
  end

  test "the latest update is delivered" do
    FederatePostJob.perform_now("update", @post.id, ActivityPub::Urls.post_url(@post), @post.updated_at.to_f)
    assert_equal "Update", JSON.parse(enqueued_jobs.last[:args].last)["type"]
  end

  test "does nothing while federation is disabled" do
    SiteSetting.current.update!(activitypub_enabled: false)
    FederatePostJob.perform_now("create", @post.id, ActivityPub::Urls.post_url(@post))
    assert_no_enqueued_jobs only: DeliverActivityJob
  end
end
