class PostEngagementQuery
  def initialize(post)
    @post = post
  end

  def views_count(since: nil)
    scope = @post.post_views
    scope = scope.since(since) if since
    scope.count
  end

  def unique_viewers(since: nil)
    scope = @post.post_views
    scope = scope.since(since) if since
    scope.distinct.count(:ip_hash)
  end

  def loves_count
    @post.loves_count
  end

  def comments_count
    @post.comments.approved.count
  end

  def engagement_rate
    views = views_count
    return 0.0 if views.zero?

    engagements = loves_count + comments_count
    (engagements.to_f / views * 100).round(1)
  end

  def traffic_sources(since: 30.days.ago)
    @post.post_views
      .since(since)
      .group(:source)
      .order("count_all DESC")
      .count
  end

  def views_by_day(since: 30.days.ago)
    @post.post_views
      .since(since)
      .group("DATE(created_at)")
      .order("DATE(created_at)")
      .count
  end
end
