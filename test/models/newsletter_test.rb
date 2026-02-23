require "test_helper"

class NewsletterTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "requires title" do
    newsletter = Newsletter.new(user: users(:admin))
    assert_not newsletter.valid?
    assert_includes newsletter.errors[:title], "can't be blank"
  end

  test "valid with title and user" do
    newsletter = Newsletter.new(title: "Test Newsletter", user: users(:admin))
    assert newsletter.valid?
  end

  test "defaults to draft status" do
    newsletter = Newsletter.create!(title: "Test", user: users(:admin))
    assert newsletter.draft?
  end

  test "send_newsletter! transitions to sending and enqueues job" do
    newsletter = newsletters(:draft_newsletter)
    assert_enqueued_with(job: SendNewsletterJob) do
      newsletter.send_newsletter!
    end
    assert newsletter.sending?
    assert_not_nil newsletter.sent_at
  end

  test "schedule! transitions to scheduled" do
    newsletter = newsletters(:draft_newsletter)
    time = 1.day.from_now
    newsletter.schedule!(time)
    assert newsletter.scheduled?
    assert_equal time.to_i, newsletter.scheduled_for.to_i
  end

  test "mark_sent! transitions to sent with count" do
    newsletter = newsletters(:sending_newsletter)
    newsletter.mark_sent!(10)
    assert newsletter.sent?
    assert_equal 10, newsletter.recipients_count
  end

  test "revert_to_draft! clears sent_at and scheduled_for" do
    newsletter = newsletters(:scheduled_newsletter)
    newsletter.revert_to_draft!
    assert newsletter.draft?
    assert_nil newsletter.sent_at
    assert_nil newsletter.scheduled_for
  end

  test "sendable? is true for draft and scheduled" do
    assert newsletters(:draft_newsletter).sendable?
    assert newsletters(:scheduled_newsletter).sendable?
    assert_not newsletters(:sent_newsletter).sendable?
    assert_not newsletters(:sending_newsletter).sendable?
  end

  test "scheduled_for must be in the future" do
    newsletter = newsletters(:draft_newsletter)
    newsletter.status = :scheduled
    newsletter.scheduled_for = 1.hour.ago
    assert_not newsletter.valid?
    assert_includes newsletter.errors[:scheduled_for], "must be in the future"
  end

  test "ready_to_send scope returns past-due scheduled newsletters" do
    newsletter = newsletters(:scheduled_newsletter)
    newsletter.update_columns(scheduled_for: 1.minute.ago)
    assert_includes Newsletter.ready_to_send, newsletter
  end

  test "ready_to_send scope excludes future scheduled newsletters" do
    assert_not_includes Newsletter.ready_to_send, newsletters(:scheduled_newsletter)
  end

  test "search scope filters by title" do
    assert_includes Newsletter.search("Draft"), newsletters(:draft_newsletter)
    assert_not_includes Newsletter.search("Draft"), newsletters(:sent_newsletter)
  end

  test "by_recency scope orders by updated_at desc" do
    old = Newsletter.create!(title: "Old", user: users(:admin), created_at: 2.days.ago, updated_at: 2.days.ago)
    recent = Newsletter.create!(title: "Recent", user: users(:admin))
    results = Newsletter.by_recency.to_a
    assert results.index(recent) < results.index(old)
  end
end
