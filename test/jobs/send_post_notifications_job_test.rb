require "test_helper"

class SendPostNotificationsJobTest < ActiveJob::TestCase
  test "enqueues email for each confirmed subscriber" do
    post = posts(:published_post)
    confirmed_count = Subscriber.confirmed.count

    assert_enqueued_jobs confirmed_count, only: ActionMailer::MailDeliveryJob do
      SendPostNotificationsJob.perform_now(post.id)
    end
  end

  test "skips subscribers who chose a digest or no post emails" do
    post = posts(:published_post)
    subscribers(:confirmed).update!(email_frequency: :weekly)
    subscribers(:with_token).update!(email_frequency: :none)
    immediate_count = Subscriber.confirmed.email_immediate.count

    assert_enqueued_jobs immediate_count, only: ActionMailer::MailDeliveryJob do
      SendPostNotificationsJob.perform_now(post.id)
    end
    assert_equal Subscriber.confirmed.count - 2, immediate_count
  end

  test "does not enqueue email for unconfirmed subscribers" do
    post = posts(:published_post)

    SendPostNotificationsJob.perform_now(post.id)

    enqueued_emails = enqueued_jobs.select { |j| j["job_class"] == "ActionMailer::MailDeliveryJob" }
    enqueued_recipients = enqueued_emails.map { |j| j["arguments"]&.last&.dig("params", "subscriber", "_aj_globalid") }.compact

    assert enqueued_recipients.none? { |r| r.include?(subscribers(:unconfirmed).id.to_s) }
  end
end
