module Admin
  class DashboardController < BaseController
    def show
      subscriber_query = SubscriberGrowthQuery.new
      @total_subscribers = subscriber_query.total
      @new_subscribers_30d = subscriber_query.new_subscribers(since: 30.days.ago)
      @subscriber_growth = subscriber_query.growth_by_day(since: 30.days.ago)
      @subscriber_trend = subscriber_query.trend_comparison(period: :month)
      @acquisition_channels = subscriber_query.acquisition_channels

      views_query = PostViewsQuery.new
      @total_views_30d = views_query.total_views(since: 30.days.ago)
      @views_by_day = views_query.views_by_day(since: 30.days.ago)
      @top_posts = views_query.top_posts(limit: 5, since: 30.days.ago)
      @views_trend = views_query.trend_comparison(period: :month)
      @top_engaged_posts = views_query.top_posts_by_engagement(limit: 5, since: 30.days.ago)

      @traffic_sources = views_query.traffic_sources(since: 30.days.ago)

      @recent_posts = Post.published.by_publication_date.limit(5).includes(:user)

      @newsletters_sent_30d = Newsletter.sent.where("sent_at >= ?", 30.days.ago).count
      @recent_newsletters = Newsletter.sent.order(sent_at: :desc).limit(5)
    end
  end
end
