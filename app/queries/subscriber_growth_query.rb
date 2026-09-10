class SubscriberGrowthQuery
  include TimeBucketing

  def initialize(relation = Subscriber.confirmed)
    @relation = relation
  end

  def total
    @relation.count
  end

  def growth_by_day(since: 30.days.ago)
    by_day(@relation.where("confirmed_at >= ?", since), :confirmed_at)
  end

  def new_subscribers(since: 30.days.ago)
    @relation.where("confirmed_at >= ?", since).count
  end

  def growth_by_month(since:)
    by_month(@relation.where("confirmed_at >= ?", since), :confirmed_at)
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

  def trend_comparison(period:)
    super(@relation, :confirmed_at, period: period)
  end

  def acquisition_channels
    @relation
      .left_joins(:source_post)
      .group(
        Arel.sql("CASE WHEN source_post_id IS NOT NULL THEN 'post' ELSE 'direct' END")
      )
      .count
  end
end
