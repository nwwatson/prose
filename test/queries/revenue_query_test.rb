require "test_helper"

class RevenueQueryTest < ActiveSupport::TestCase
  setup do
    @query = RevenueQuery.new
  end

  test "monthly_recurring_revenue sums active memberships" do
    mrr = @query.monthly_recurring_revenue
    assert mrr >= 0
  end

  test "annual_recurring_revenue is 12x MRR" do
    mrr = @query.monthly_recurring_revenue
    assert_equal mrr * 12, @query.annual_recurring_revenue
  end

  test "total_paid_members counts current memberships" do
    count = @query.total_paid_members
    assert count >= 1
  end

  test "churn_rate returns a percentage" do
    rate = @query.churn_rate(since: 90.days.ago)
    assert rate >= 0.0
  end

  test "revenue_by_month returns hash of months" do
    result = @query.revenue_by_month(since: 12.months.ago)
    assert_kind_of Hash, result
  end
end
