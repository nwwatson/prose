require "test_helper"

class Post::FederatableTest < ActiveSupport::TestCase
  include ActivityPubTestHelper

  setup { enable_federation! }

  test "publishing a post federates a Create" do
    post = posts(:draft_post)

    assert_enqueued_with(job: FederatePostJob, args: [ "create", post.id, ActivityPub::Urls.post_url(post) ]) do
      post.publish!
    end
  end

  test "editing a published post federates a coalesced Update" do
    post = posts(:published_post)

    post.update!(title: "A new title")

    job = enqueued_jobs.find { |j| j[:job] == FederatePostJob }
    assert_equal "update", job[:args].first
    assert job[:at], "update is delayed so autosave bursts are coalesced"
  end

  test "settings-only changes to a published post don't federate" do
    post = posts(:published_post)
    post.update!(content: "<p>Body</p>")
    clear_enqueued_jobs

    assert_no_enqueued_jobs(only: FederatePostJob) { post.update!(featured: true) }
  end

  test "unpublishing a post federates a Delete" do
    post = posts(:published_post)
    assert_enqueued_with(job: FederatePostJob, args: [ "delete", post.id, ActivityPub::Urls.post_url(post) ]) do
      post.revert_to_draft!
    end
  end

  test "destroying a published post federates a Delete" do
    post = posts(:published_post)
    assert_enqueued_with(job: FederatePostJob, args: [ "delete", post.id, ActivityPub::Urls.post_url(post) ]) do
      post.destroy!
    end
  end

  test "drafts changing never federate" do
    assert_no_enqueued_jobs(only: FederatePostJob) { posts(:draft_post).update!(title: "Still a draft") }
  end

  test "nothing federates while federation is disabled" do
    SiteSetting.current.update!(activitypub_enabled: false)
    assert_no_enqueued_jobs(only: FederatePostJob) { posts(:draft_post).publish! }
  end
end
