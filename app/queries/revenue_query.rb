class RevenueQuery
  def initialize(relation = Membership.all)
    @relation = relation
  end

  def monthly_recurring_revenue
    active_memberships = @relation.current.includes(:membership_tier)
    active_memberships.sum do |m|
      tier = m.membership_tier
      tier.month? ? tier.price_cents : (tier.price_cents / 12.0).round
    end
  end

  def annual_recurring_revenue
    monthly_recurring_revenue * 12
  end

  def total_paid_members
    @relation.current.count
  end

  def churn_rate(since: 30.days.ago)
    canceled = @relation.where(status: :canceled).where("canceled_at >= ?", since).count
    total_at_start = @relation.where("created_at < ?", since).count
    return 0.0 if total_at_start.zero?

    (canceled.to_f / total_at_start * 100).round(1)
  end

  def revenue_by_month(since: 12.months.ago)
    @relation
      .current
      .joins(:membership_tier)
      .where("memberships.created_at >= ?", since)
      .group("strftime('%Y-%m', memberships.created_at)")
      .sum("membership_tiers.price_cents")
  end
end
