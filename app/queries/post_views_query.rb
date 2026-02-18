class PostViewsQuery
  def initialize(relation = PostView.all)
    @relation = relation
  end

  def total_views(since: nil)
    scope = @relation
    scope = scope.since(since) if since
    scope.count
  end

  def views_by_day(since: 30.days.ago)
    @relation
      .since(since)
      .group("DATE(created_at)")
      .order("DATE(created_at)")
      .count
  end

  def traffic_sources(since: 30.days.ago)
    @relation
      .since(since)
      .group(:source)
      .order("count_all DESC")
      .count
  end

  def top_posts(limit: 10, since: 30.days.ago)
    Post.joins(:post_views)
      .where(post_views: { created_at: since.. })
      .group("posts.id")
      .order("COUNT(post_views.id) DESC")
      .limit(limit)
      .select("posts.*, COUNT(post_views.id) AS views_count")
  end

  def unique_viewers(since: nil)
    scope = @relation
    scope = scope.since(since) if since
    scope.distinct.count(:ip_hash)
  end
end
