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

  def trend_comparison(period:)
    case period
    when :week
      current_start = 7.days.ago
      previous_start = 14.days.ago
      previous_end = 7.days.ago
    when :month
      current_start = 30.days.ago
      previous_start = 60.days.ago
      previous_end = 30.days.ago
    else
      raise ArgumentError, "period must be :week or :month"
    end

    current_views = @relation.where(created_at: current_start..).count
    previous_views = @relation.where(created_at: previous_start..previous_end).count

    percentage_change = if previous_views.zero?
      current_views.zero? ? 0.0 : 100.0
    else
      ((current_views - previous_views).to_f / previous_views * 100).round(1)
    end

    {
      current: current_views,
      previous: previous_views,
      change: percentage_change
    }
  end

  def top_posts_by_engagement(limit: 10, since: 30.days.ago)
    Post.published
      .joins(:post_views)
      .where(post_views: { created_at: since.. })
      .group("posts.id")
      .select(
        "posts.*",
        "COUNT(post_views.id) AS views_count",
        "COUNT(DISTINCT post_views.ip_hash) AS unique_viewers_count",
        "CAST(posts.loves_count AS FLOAT) / NULLIF(COUNT(DISTINCT post_views.ip_hash), 0) AS engagement_score"
      )
      .order(Arel.sql("engagement_score DESC NULLS LAST"))
      .limit(limit)
  end
end
