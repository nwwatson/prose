module Admin
  class TrafficController < BaseController
    include Admin::AnalyticsRangeable

    ALLOWED_RANGES = %w[7d 30d 90d all].freeze

    def show
      range = analytics_range(default: "30d", allowed: ALLOWED_RANGES)
      @range = range.key
      since = range.since

      views_query = PostViewsQuery.new
      referrer_query = ReferrerAnalyticsQuery.new

      @total_views = views_query.total_views(since: since)
      @unique_viewers = views_query.unique_viewers(since: since)
      @views_by_day = views_query.views_by_day(since: since)
      @traffic_sources = views_query.traffic_sources(since: since)
      @top_source = @traffic_sources.first&.first || "direct"

      @top_domains = referrer_query.top_domains(limit: 15, since: since)
      @utm_sources = referrer_query.utm_sources(since: since)
      @utm_mediums = referrer_query.utm_mediums(since: since)
      @utm_campaigns = referrer_query.utm_campaigns(since: since)
    end
  end
end
