require "test_helper"

class DeliverActivityJobTest < ActiveJob::TestCase
  include ActivityPubTestHelper

  setup do
    enable_federation!
    @actor = remote_actor.tap(&:follow!)
  end

  def with_post_result(result, &block)
    calls = []
    implementation = lambda do |url, body|
      calls << [ url, body ]
      raise result if result.is_a?(Exception)

      result
    end
    with_singleton_stub(ActivityPub::HttpClient, :post, implementation) { block.call(calls) }
  end

  test "posts the activity to the inbox" do
    with_post_result("") do |calls|
      DeliverActivityJob.perform_now("https://remote.example/inbox", "{}")
      assert_equal [ [ "https://remote.example/inbox", "{}" ] ], calls
    end
  end

  test "410 Gone drops followers behind that inbox" do
    with_post_result(ActivityPub::HttpClient::Error.new("gone", status: 410)) do
      DeliverActivityJob.perform_now("https://remote.example/inbox", "{}")
    end
    assert_not @actor.reload.follower?
  end

  test "other client errors are not retried" do
    with_post_result(ActivityPub::HttpClient::Error.new("bad", status: 400)) do
      assert_no_enqueued_jobs(only: DeliverActivityJob) { DeliverActivityJob.perform_now("https://remote.example/inbox", "{}") }
    end
  end

  test "server errors are retried" do
    with_post_result(ActivityPub::HttpClient::Error.new("down", status: 503)) do
      assert_enqueued_with(job: DeliverActivityJob) { DeliverActivityJob.perform_now("https://remote.example/inbox", "{}") }
    end
  end

  test "skipped while federation is disabled" do
    SiteSetting.current.update!(activitypub_enabled: false)
    with_post_result("") do |calls|
      DeliverActivityJob.perform_now("https://remote.example/inbox", "{}")
      assert_empty calls
    end
  end
end
