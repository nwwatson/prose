class PostEngagementQuery
  include TimeBucketing

  def initialize(post)
    @post = post
    @views_query = PostViewsQuery.new(post.post_views)
  end

  def views_count(since: nil)
    @views_query.total_views(since: since)
  end

  def unique_viewers(since: nil)
    @views_query.unique_viewers(since: since)
  end

  def loves_count
    @post.loves_count
  end

  def comments_count
    @post.comments.approved.count
  end

  def engagement_rate
    percentage(loves_count + comments_count, views_count)
  end

  def traffic_sources(since: 30.days.ago)
    @views_query.traffic_sources(since: since)
  end

  def views_by_day(since: 30.days.ago)
    @views_query.views_by_day(since: since)
  end
end
