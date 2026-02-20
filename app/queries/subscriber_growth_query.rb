class SubscriberGrowthQuery
  def initialize(relation = Subscriber.confirmed)
    @relation = relation
  end

  def total
    @relation.count
  end

  def growth_by_day(since: 30.days.ago)
    @relation
      .where("confirmed_at >= ?", since)
      .group("DATE(confirmed_at)")
      .order("DATE(confirmed_at)")
      .count
  end

  def new_subscribers(since: 30.days.ago)
    @relation.where("confirmed_at >= ?", since).count
  end

  def growth_by_month(since:)
    @relation
      .where("confirmed_at >= ?", since)
      .group(Arel.sql("strftime('%Y-%m', confirmed_at)"))
      .order(Arel.sql("strftime('%Y-%m', confirmed_at)"))
      .count
  end

  def cumulative_by_month(since:)
    baseline = @relation.where("confirmed_at < ?", since).count
    monthly = growth_by_month(since: since)
    running = baseline

    monthly.transform_values { |count| running += count }
  end

  def top_posts_by_subscribers(limit: 10)
    Post.published
      .joins(:attributed_subscribers)
      .where.not(attributed_subscribers: { confirmed_at: nil })
      .group("posts.id")
      .select("posts.*, COUNT(attributed_subscribers.id) AS subscribers_count")
      .order("subscribers_count DESC")
      .limit(limit)
  end

  def most_recent_post_subscribers
    post = Post.published.order(published_at: :desc).first
    return nil unless post

    count = @relation.where(source_post_id: post.id).count
    { post: post, count: count }
  end
end
