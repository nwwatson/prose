module Admin
  class DashboardController < BaseController
    def show
      @total_subscribers = SubscriberGrowthQuery.new.total
      @new_subscribers_30d = SubscriberGrowthQuery.new.new_subscribers(since: 30.days.ago)
      @subscriber_growth = SubscriberGrowthQuery.new.growth_by_day(since: 30.days.ago)

      views_query = PostViewsQuery.new
      @total_views_30d = views_query.total_views(since: 30.days.ago)
      @views_by_day = views_query.views_by_day(since: 30.days.ago)
      @top_posts = views_query.top_posts(limit: 5, since: 30.days.ago)

      @recent_posts = Post.published.by_publication_date.limit(5).includes(:user)
    end
  end
end
