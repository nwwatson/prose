module Admin
  class TrafficController < BaseController
    def show
      since = range_to_date(params[:range])
      @range = params[:range] || "30d"

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
