class ReferrerAnalyticsQuery
  def initialize(relation = PostView.all)
    @relation = relation
  end

  def top_domains(limit: 10, since: 30.days.ago)
    breakdown(:referrer_domain, since: since, limit: limit)
  end

  def utm_sources(since: 30.days.ago)
    breakdown(:utm_source, since: since)
  end

  def utm_mediums(since: 30.days.ago)
    breakdown(:utm_medium, since: since)
  end

  def utm_campaigns(since: 30.days.ago)
    breakdown(:utm_campaign, since: since)
  end

  def campaign_detail(campaign, since: 30.days.ago)
    scope = @relation.since(since).with_campaign(campaign)
    {
      total_views: scope.count,
      sources: scope.group(:utm_source).order("count_all DESC").count,
      mediums: scope.group(:utm_medium).order("count_all DESC").count
    }
  end

  private

  # Views per value of +column+ (blank rows excluded), most viewed first.
  def breakdown(column, since:, limit: nil)
    @relation
      .since(since)
      .where.not(column => nil)
      .group(column)
      .order("count_all DESC")
      .limit(limit)
      .count
  end
end
