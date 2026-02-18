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
end
