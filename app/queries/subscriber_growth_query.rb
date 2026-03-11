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

    current_count = @relation.where(confirmed_at: current_start..).count
    previous_count = @relation.where(confirmed_at: previous_start..previous_end).count

    percentage_change = if previous_count.zero?
      current_count.zero? ? 0.0 : 100.0
    else
      ((current_count - previous_count).to_f / previous_count * 100).round(1)
    end

    {
      current: current_count,
      previous: previous_count,
      change: percentage_change
    }
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
