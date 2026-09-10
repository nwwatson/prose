class PostViewsQuery
  include TimeBucketing

  def initialize(relation = PostView.all)
    @relation = relation
  end

  def total_views(since: nil)
    scope = @relation
    scope = scope.since(since) if since
    scope.count
  end

  def views_by_day(since: 30.days.ago)
    by_day(@relation.since(since), :created_at)
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
    super(@relation, :created_at, period: period)
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
