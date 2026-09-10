class RevenueQuery
  include TimeBucketing

  def initialize(relation = Membership.all)
    @relation = relation
  end

  def monthly_recurring_revenue
    @relation.current.joins(:membership_tier).sum(
      Arel.sql(<<~SQL.squish)
        CASE WHEN membership_tiers.interval = #{MembershipTier.intervals[:month].to_i}
          THEN price_cents
          ELSE CAST(ROUND(price_cents / 12.0) AS INTEGER)
        END
      SQL
    )
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
    percentage(canceled, total_at_start)
  end

  # NOTE: sums raw price_cents without normalizing yearly tiers to a monthly
  # equivalent, unlike monthly_recurring_revenue above.
  def revenue_by_month(since: 12.months.ago)
    scope = @relation.current.joins(:membership_tier).where("memberships.created_at >= ?", since)
    scope.group(month_bucket(scope, :created_at)).sum("membership_tiers.price_cents")
  end
end
