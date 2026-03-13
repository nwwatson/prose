class MembershipGrowthQuery
  def initialize(relation = Membership.all)
    @relation = relation
  end

  def new_members(since: 30.days.ago)
    @relation.where("created_at >= ?", since).count
  end

  def cancellations(since: 30.days.ago)
    @relation.where(status: :canceled).where("canceled_at >= ?", since).count
  end

  def net_growth(since: 30.days.ago)
    new_members(since: since) - cancellations(since: since)
  end

  def growth_by_month(since: 12.months.ago)
    new_by_month = @relation
      .where("created_at >= ?", since)
      .group("strftime('%Y-%m', created_at)")
      .count

    canceled_by_month = @relation
      .where(status: :canceled)
      .where("canceled_at >= ?", since)
      .group("strftime('%Y-%m', canceled_at)")
      .count

    months = new_by_month.keys | canceled_by_month.keys
    months.sort.map do |month|
      { month: month, new: new_by_month[month] || 0, canceled: canceled_by_month[month] || 0 }
    end
  end
end
