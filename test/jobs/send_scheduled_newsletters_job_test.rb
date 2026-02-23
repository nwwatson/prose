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
end
