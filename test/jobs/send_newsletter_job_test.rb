require "test_helper"

class SendNewsletterJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper
  include EmailProviderHelper

  setup do
    ActionMailer::Base.deliveries.clear
    @newsletter = newsletters(:sending_newsletter)
  end

  # --- SMTP ---

  test "delivers to every confirmed subscriber and records one delivery each" do
    confirmed_count = Subscriber.confirmed.count

    assert_emails confirmed_count do
      assert_difference "NewsletterDelivery.count", confirmed_count do
        SendNewsletterJob.perform_now(@newsletter.id)
      end
    end

    assert @newsletter.reload.sent?
    assert_equal confirmed_count, @newsletter.recipients_count
    assert @newsletter.newsletter_deliveries.all? { |delivery| delivery.sent_at.present? }
  end

  test "does not resend to subscribers who already have a delivery and counts them as recipients" do
    @newsletter.newsletter_deliveries.create!(subscriber: subscribers(:confirmed), sent_at: Time.current)

    assert_emails Subscriber.confirmed.count - 1 do
      SendNewsletterJob.perform_now(@newsletter.id)
    end

    assert_not_includes ActionMailer::Base.deliveries.flat_map(&:to), subscribers(:confirmed).email
    assert_equal Subscriber.confirmed.count, @newsletter.reload.recipients_count
  end

  test "SMTP rejection partway through: others are delivered, the retry sends only to the rejected subscriber" do
    rejected = subscribers(:confirmed).email
    others = Subscriber.confirmed.where.not(email: rejected).pluck(:email)
    assert others.any?, "needs subscribers on both sides of the failure"

    with_smtp_rejecting(->(to) { to == rejected }) do
      assert_enqueued_with(job: SendNewsletterJob, args: [ @newsletter.id ]) do
        SendNewsletterJob.perform_now(@newsletter.id)
      end
    end

    assert_equal others.sort, ActionMailer::Base.deliveries.flat_map(&:to).sort
    assert_not delivered?(subscribers(:confirmed)), "a rejected recipient must not be recorded as delivered"
    assert @newsletter.reload.sending?, "the newsletter is not finished while a recipient is outstanding"

    ActionMailer::Base.deliveries.clear
    perform_enqueued_jobs(only: SendNewsletterJob)

    assert_equal [ rejected ], ActionMailer::Base.deliveries.flat_map(&:to), "the retry must not resend to delivered subscribers"
    assert @newsletter.reload.sent?
    assert_equal Subscriber.confirmed.count, @newsletter.recipients_count
  end

  test "rerunning after a crash sends to everyone not yet delivered and to nobody twice" do
    delivered = Subscriber.confirmed.order(:id).first
    @newsletter.newsletter_deliveries.create!(subscriber: delivered, sent_at: Time.current)

    SendNewsletterJob.perform_now(@newsletter.id)

    sent_to = ActionMailer::Base.deliveries.flat_map(&:to)
    assert_equal sent_to.uniq, sent_to
    assert_equal Subscriber.confirmed.where.not(id: delivered.id).pluck(:email).sort, sent_to.sort
  end

  test "once retries are exhausted the newsletter is marked sent with the delivered count" do
    rejected = subscribers(:confirmed)

    with_smtp_rejecting(->(to) { to == rejected.email }) do
      perform_enqueued_jobs(only: SendNewsletterJob) do
        SendNewsletterJob.perform_later(@newsletter.id)
      end
    end

    sent_to = ActionMailer::Base.deliveries.flat_map(&:to)
    assert_equal sent_to.uniq, sent_to, "retries must not resend to delivered subscribers"
    assert @newsletter.reload.sent?
    assert_equal Subscriber.confirmed.count - 1, @newsletter.recipients_count
    assert_not delivered?(rejected)
  end

  test "stops a run after repeated consecutive rejections and leaves the rest for the retry" do
    Subscriber.confirmed.destroy_all
    (SendNewsletterJob::MAX_CONSECUTIVE_FAILURES + 5).times { |i| Subscriber.create!(email: "down#{i}@example.com", confirmed_at: 1.week.ago) }

    attempts = 0
    with_smtp_rejecting(->(_to) { attempts += 1 }) do
      SendNewsletterJob.perform_now(@newsletter.id)
    end

    assert_equal SendNewsletterJob::MAX_CONSECUTIVE_FAILURES, attempts
    assert_equal 0, @newsletter.newsletter_deliveries.count
    assert_enqueued_jobs 1, only: SendNewsletterJob
  end

  test "does nothing for a newsletter that is no longer sending" do
    @newsletter.mark_sent!(0)
    Subscriber.create!(email: "late@example.com", confirmed_at: Time.current)

    assert_no_emails do
      SendNewsletterJob.perform_now(@newsletter.id)
    end
    assert_equal 0, @newsletter.newsletter_deliveries.count
  end

  test "writes one delivery row per recipient and no queued jobs" do
    assert_no_enqueued_jobs do
      SendNewsletterJob.perform_now(@newsletter.id)
    end

    inserts = 0
    counter = ->(*, payload) { inserts += 1 if payload[:sql].match?(/\AINSERT INTO "newsletter_deliveries"/i) }
    Subscriber.create!(email: "one-more@example.com", confirmed_at: 1.week.ago)
    @newsletter.reload.update!(status: :sending)

    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
      SendNewsletterJob.perform_now(@newsletter.id)
    end

    assert_equal 1, inserts
  end

  test "excludes delivered subscribers with a subquery instead of a SELECT per subscriber" do
    Subscriber.confirmed.destroy_all
    10.times { |i| Subscriber.create!(email: "batch#{i}@example.com", confirmed_at: 1.week.ago) }
    Subscriber.confirmed.limit(3).each { |subscriber| @newsletter.newsletter_deliveries.create!(subscriber: subscriber, sent_at: Time.current) }

    delivery_query_count = 0
    counter = ->(*, payload) { delivery_query_count += 1 if payload[:name] == "NewsletterDelivery Load" }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
      SendNewsletterJob.perform_now(@newsletter.id)
    end

    assert_equal 10, @newsletter.reload.recipients_count
    assert_equal 0, delivery_query_count
  end

  # --- SendGrid ---

  test "SendGrid: delivers through one API client and records each accepted recipient" do
    fake = EmailProviderHelper::FakeSendgridClient.new

    with_fake_sendgrid(fake) do |clients_built|
      SendNewsletterJob.perform_now(@newsletter.id)
      assert_equal 1, clients_built.call
    end

    assert_equal Subscriber.confirmed.pluck(:email).sort, fake.accepted.sort
    assert @newsletter.reload.sent?
    assert_equal Subscriber.confirmed.count, @newsletter.recipients_count
  end

  test "SendGrid non-2xx partway through: not counted as sent, and the retry sends only to that subscriber" do
    rejected = subscribers(:confirmed).email
    first_run = EmailProviderHelper::FakeSendgridClient.new { |to| to == rejected ? 500 : 202 }

    with_fake_sendgrid(first_run) do
      SendNewsletterJob.perform_now(@newsletter.id)
    end

    assert_equal Subscriber.confirmed.count, first_run.attempted.size, "one rejection must not stop the others"
    assert_not_includes first_run.accepted, rejected
    assert_not delivered?(subscribers(:confirmed))
    assert_equal Subscriber.confirmed.count - 1, @newsletter.newsletter_deliveries.count
    assert @newsletter.reload.sending?
    assert_enqueued_jobs 1, only: SendNewsletterJob

    retry_run = EmailProviderHelper::FakeSendgridClient.new
    with_fake_sendgrid(retry_run) do
      perform_enqueued_jobs(only: SendNewsletterJob)
    end

    assert_equal [ rejected ], retry_run.attempted
    assert @newsletter.reload.sent?
    assert_equal Subscriber.confirmed.count, @newsletter.recipients_count
  end

  test "SendGrid network error partway through is retried for that subscriber only" do
    rejected = subscribers(:confirmed).email
    first_run = EmailProviderHelper::FakeSendgridClient.new { |to| to == rejected ? raise(Net::ReadTimeout) : 202 }

    with_fake_sendgrid(first_run) do
      SendNewsletterJob.perform_now(@newsletter.id)
    end

    assert_not delivered?(subscribers(:confirmed))
    assert_equal Subscriber.confirmed.count - 1, @newsletter.newsletter_deliveries.count

    retry_run = EmailProviderHelper::FakeSendgridClient.new
    with_fake_sendgrid(retry_run) do
      perform_enqueued_jobs(only: SendNewsletterJob)
    end

    assert_equal [ rejected ], retry_run.attempted
    assert_equal Subscriber.confirmed.count, @newsletter.reload.recipients_count
  end

  private

  def delivered?(subscriber)
    @newsletter.newsletter_deliveries.exists?(subscriber: subscriber)
  end
end
