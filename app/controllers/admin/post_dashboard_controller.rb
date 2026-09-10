module Admin
  class PostDashboardController < BaseController
    include Admin::PostScoped

    def show
      @engagement = PostEngagementQuery.new(@post)
      @views_count = @engagement.views_count
      @unique_viewers = @engagement.unique_viewers
      @engagement_rate = @engagement.engagement_rate
      @traffic_sources = @engagement.traffic_sources
      @views_by_day = @engagement.views_by_day
    end
  end
end
