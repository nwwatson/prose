require "test_helper"

class NewsletterOverviewQueryTest < ActiveSupport::TestCase
  setup do
    @query = NewsletterOverviewQuery.new
  end

  test "total_sent returns count of sent newsletters" do
    assert_equal Newsletter.sent.count, @query.total_sent
  end

  test "total_sent with since filter" do
    count = @query.total_sent(since: 30.days.ago)
    assert count >= 0
  end

  test "total_deliveries returns sum of recipients_count" do
    expected = Newsletter.sent.sum(:recipients_count)
    assert_equal expected, @query.total_deliveries
  end

  test "average_open_rate returns a float" do
    rate = @query.average_open_rate
    assert_kind_of Float, rate
    assert rate >= 0.0
  end

  test "recent_newsletters returns sent newsletters ordered by sent_at desc" do
    results = @query.recent_newsletters(limit: 5)
    assert results.all?(&:sent?)
    if results.size > 1
      assert results.first.sent_at >= results.last.sent_at
    end
  end
end
