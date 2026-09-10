module Admin
  class DashboardController < BaseController
    def show
      since = AnalyticsRange.new("30d").since

      subscriber_query = SubscriberGrowthQuery.new
      @total_subscribers = subscriber_query.total
      @new_subscribers_30d = subscriber_query.new_subscribers(since: since)
      @subscriber_growth = subscriber_query.growth_by_day(since: since)
      @subscriber_trend = subscriber_query.trend_comparison(period: :month)
      @acquisition_channels = subscriber_query.acquisition_channels

      views_query = PostViewsQuery.new
      @total_views_30d = views_query.total_views(since: since)
      @views_by_day = views_query.views_by_day(since: since)
      @top_posts = views_query.top_posts(limit: 5, since: since)
      @views_trend = views_query.trend_comparison(period: :month)
      @top_engaged_posts = views_query.top_posts_by_engagement(limit: 5, since: since)

      @traffic_sources = views_query.traffic_sources(since: since)

      @recent_posts = Post.published.by_publication_date.limit(5).with_author
      @published_posts_count = Post.published.count

      @newsletters_sent_30d = Newsletter.sent.where("sent_at >= ?", since).count
      @recent_newsletters = Newsletter.sent.order(sent_at: :desc).limit(5)
    end
  end
end
