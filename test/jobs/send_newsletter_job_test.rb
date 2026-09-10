require "test_helper"

class SendNewsletterJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  test "creates deliveries and enqueues emails to confirmed subscribers" do
    newsletter = newsletters(:sending_newsletter)
    confirmed_count = Subscriber.confirmed.count

    assert_emails confirmed_count do
      perform_enqueued_jobs do
        SendNewsletterJob.perform_now(newsletter.id)
      end
    end

    assert newsletter.reload.sent?
    assert_equal confirmed_count, newsletter.recipients_count
  end

  test "skips already delivered subscribers (idempotent)" do
    newsletter = newsletters(:sending_newsletter)
    subscriber = subscribers(:confirmed)
    newsletter.newsletter_deliveries.create!(subscriber: subscriber, sent_at: Time.current)

    confirmed_count = Subscriber.confirmed.count
    expected_new = confirmed_count - 1

    SendNewsletterJob.perform_now(newsletter.id)

    assert_equal expected_new, newsletter.reload.recipients_count
  end

  test "marks newsletter as sent with correct count" do
    newsletter = newsletters(:sending_newsletter)
    SendNewsletterJob.perform_now(newsletter.id)

    newsletter.reload
    assert newsletter.sent?
    assert_equal Subscriber.confirmed.count, newsletter.recipients_count
  end

  test "batches newsletter_deliveries lookups instead of querying per subscriber" do
    newsletter = newsletters(:sending_newsletter)
    Subscriber.confirmed.destroy_all

    10.times { |i| Subscriber.create!(email: "batch#{i}@example.com", confirmed_at: 1.week.ago) }
    delivered = Subscriber.confirmed.limit(3)
    delivered.each { |subscriber| newsletter.newsletter_deliveries.create!(subscriber: subscriber, sent_at: Time.current) }

    delivery_query_count = 0
    subscription = ActiveSupport::Notifications.subscribe("sql.active_record") do |_name, _start, _finish, _id, payload|
      delivery_query_count += 1 if payload[:name] == "NewsletterDelivery Load"
    end

    SendNewsletterJob.perform_now(newsletter.id)

    ActiveSupport::Notifications.unsubscribe(subscription)

    assert_equal 7, newsletter.reload.recipients_count
    assert_equal 0, delivery_query_count, "expected the exclusion check to be a subquery, not a separate SELECT per subscriber"
  end
end
