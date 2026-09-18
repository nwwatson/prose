require "test_helper"

class SendDigestsJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    Subscriber.update_all(email_frequency: Subscriber.email_frequencies[:immediate], last_digest_at: nil)
    @weekly = subscribers(:confirmed)
    @weekly.update_columns(email_frequency: Subscriber.email_frequencies[:weekly])
  end

  test "sends a digest of the week's live posts to weekly subscribers" do
    freeze_time do
      expected_ids = Post.live.where(published_at: 1.week.ago...Time.current).by_publication_date.pluck(:id)
      assert expected_ids.any?

      assert_enqueued_email_with DigestMailer, :digest, args: [ @weekly, expected_ids, expected_ids.size ] do
        SendDigestsJob.perform_now("weekly")
      end

      assert_equal Time.current, @weekly.reload.last_digest_at
    end
  end

  test "only emails subscribers on the given frequency" do
    assert_enqueued_emails 1 do
      SendDigestsJob.perform_now("weekly")
    end

    assert_no_enqueued_emails do
      SendDigestsJob.perform_now("monthly")
    end
  end

  test "skips unconfirmed and unsubscribed subscribers" do
    subscribers(:unconfirmed).update_columns(email_frequency: Subscriber.email_frequencies[:weekly])
    subscribers(:with_token).update_columns(email_frequency: Subscriber.email_frequencies[:weekly], unsubscribed_at: 1.day.ago)

    assert_enqueued_emails 1 do
      SendDigestsJob.perform_now("weekly")
    end
  end

  test "skips subscribers with no new posts and keeps their cursor" do
    cursor = 1.minute.ago.change(usec: 0)
    @weekly.update_columns(last_digest_at: cursor)

    assert_no_enqueued_emails do
      SendDigestsJob.perform_now("weekly")
    end

    assert_equal cursor, @weekly.reload.last_digest_at
  end

  test "a repeated run does not resend the same posts" do
    SendDigestsJob.perform_now("weekly")

    assert_no_enqueued_emails do
      SendDigestsJob.perform_now("weekly")
    end
  end

  test "covers posts since the subscriber's last digest" do
    @weekly.update_columns(last_digest_at: 3.hours.ago)

    assert_enqueued_email_with DigestMailer, :digest, args: [ @weekly, [ posts(:featured_post).id ], 1 ] do
      SendDigestsJob.perform_now("weekly")
    end
  end

  test "excludes drafts and future scheduled posts" do
    SendDigestsJob.perform_now("weekly")

    post_ids = enqueued_jobs.find { |job| job["job_class"] == "ActionMailer::MailDeliveryJob" }["arguments"][3]["args"][1]
    assert_not_includes post_ids, posts(:draft_post).id
    assert_not_includes post_ids, posts(:scheduled_post).id
  end

  test "caps the listed posts but reports the full count" do
    with_const(SendDigestsJob, :POST_LIMIT, 2) do
      freeze_time do
        all_ids = Post.live.where(published_at: 1.week.ago...Time.current).by_publication_date.pluck(:id)
        assert_operator all_ids.size, :>, 2

        assert_enqueued_email_with DigestMailer, :digest, args: [ @weekly, all_ids.first(2), all_ids.size ] do
          SendDigestsJob.perform_now("weekly")
        end
      end
    end
  end

  test "rejects an unknown frequency" do
    assert_raises(ArgumentError) { SendDigestsJob.perform_now("immediate") }
  end

  private

  def with_const(klass, name, value)
    original = klass.const_get(name)
    klass.send(:remove_const, name)
    klass.const_set(name, value)
    yield
  ensure
    klass.send(:remove_const, name)
    klass.const_set(name, original)
  end
end
