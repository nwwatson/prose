require "test_helper"

class SendScheduledNewslettersJobTest < ActiveJob::TestCase
  test "sends newsletters that are past their scheduled time" do
    newsletter = newsletters(:scheduled_newsletter)
    newsletter.update_columns(scheduled_for: 1.minute.ago)

    assert_enqueued_with(job: SendNewsletterJob) do
      SendScheduledNewslettersJob.perform_now
    end

    assert newsletter.reload.sending?
  end

  test "does not send newsletters scheduled for the future" do
    assert_no_enqueued_jobs(only: SendNewsletterJob) do
      SendScheduledNewslettersJob.perform_now
    end
  end

  test "a newsletter that fails to send is reported and does not block later ones" do
    scheduled = newsletters(:scheduled_newsletter)
    other = Newsletter.create!(title: "Also due", user: scheduled.user, status: :scheduled, scheduled_for: 1.day.from_now)
    # find_each runs in id order, so break the newsletter that comes first.
    failing, later = [ scheduled, other ].sort_by(&:id)
    failing.update_columns(title: "", scheduled_for: 1.minute.ago)
    later.update_columns(scheduled_for: 1.minute.ago)

    assert_error_reported(ActiveRecord::RecordInvalid) do
      assert_enqueued_with(job: SendNewsletterJob, args: [ later.id ]) do
        SendScheduledNewslettersJob.perform_now
      end
    end

    assert failing.reload.scheduled?
    assert later.reload.sending?
  end
end
