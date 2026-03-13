module Admin
  class RevenueController < BaseController
    def show
      since = range_to_date(params[:range])
      @range = params[:range] || "30d"

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

    private

    def range_to_date(range)
      case range
      when "7d" then 7.days.ago
      when "90d" then 90.days.ago
      when "all" then Time.at(0)
      else 30.days.ago
      end
    end
  end
end
