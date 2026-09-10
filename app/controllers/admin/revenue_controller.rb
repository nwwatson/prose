module Admin
  class RevenueController < BaseController
    include Admin::AnalyticsRangeable

    ALLOWED_RANGES = %w[7d 30d 90d all].freeze

    def show
      range = analytics_range(default: "30d", allowed: ALLOWED_RANGES)
      @range = range.key
      since = range.since

      revenue_query = RevenueQuery.new
      growth_query = MembershipGrowthQuery.new

      @mrr = revenue_query.monthly_recurring_revenue
      @arr = revenue_query.annual_recurring_revenue
      @total_paid = revenue_query.total_paid_members
      @churn_rate = revenue_query.churn_rate(since: since)
      @revenue_by_month = revenue_query.revenue_by_month(since: 12.months.ago)

      @new_members = growth_query.new_members(since: since)
      @cancellations = growth_query.cancellations(since: since)
      @net_growth = growth_query.net_growth(since: since)
      @growth_by_month = growth_query.growth_by_month(since: 12.months.ago)
    end
  end
end
