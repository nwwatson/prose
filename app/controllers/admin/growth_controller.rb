module Admin
  class GrowthController < BaseController
    include Admin::AnalyticsRangeable

    ALLOWED_RANGES = %w[6mo 12mo 24mo all].freeze

    def show
      query = SubscriberGrowthQuery.new
      range = analytics_range(default: "12mo", allowed: ALLOWED_RANGES)
      @range = range.key
      since = range.since

      @total_subscribers = query.total
      @new_subscribers = query.new_subscribers(since: since)
      @monthly_data = query.growth_by_month(since: since)
      @cumulative_data = query.cumulative_by_month(since: since)
      @top_posts = query.top_posts_by_subscribers(limit: 10)
      @latest_post_data = query.most_recent_post_subscribers
    end
  end
end
