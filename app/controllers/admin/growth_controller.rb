module Admin
  class GrowthController < BaseController
    def show
      query = SubscriberGrowthQuery.new
      since = range_to_date(params[:range])

      @range = params[:range] || "12mo"
      @total_subscribers = query.total
      @new_subscribers = query.new_subscribers(since: since)
      @monthly_data = query.growth_by_month(since: since)
      @cumulative_data = query.cumulative_by_month(since: since)
      @top_posts = query.top_posts_by_subscribers(limit: 10)
      @latest_post_data = query.most_recent_post_subscribers
    end

    private

    def range_to_date(range)
      case range
      when "6mo" then 6.months.ago
      when "24mo" then 24.months.ago
      when "all" then Time.at(0)
      else 12.months.ago
      end
    end
  end
end
