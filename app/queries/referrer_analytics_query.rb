class ReferrerAnalyticsQuery
  def initialize(relation = PostView.all)
    @relation = relation
  end

  def top_domains(limit: 10, since: 30.days.ago)
    @relation
      .since(since)
      .where.not(referrer_domain: nil)
      .group(:referrer_domain)
      .order("count_all DESC")
      .limit(limit)
      .count
  end

  def utm_sources(since: 30.days.ago)
    @relation
      .since(since)
      .with_utm
      .group(:utm_source)
      .order("count_all DESC")
      .count
  end

  def utm_mediums(since: 30.days.ago)
    @relation
      .since(since)
      .where.not(utm_medium: nil)
      .group(:utm_medium)
      .order("count_all DESC")
      .count
  end

  def utm_campaigns(since: 30.days.ago)
    @relation
      .since(since)
      .where.not(utm_campaign: nil)
      .group(:utm_campaign)
      .order("count_all DESC")
      .count
  end

  def campaign_detail(campaign, since: 30.days.ago)
    scope = @relation.since(since).with_campaign(campaign)
    {
      total_views: scope.count,
      sources: scope.group(:utm_source).order("count_all DESC").count,
      mediums: scope.group(:utm_medium).order("count_all DESC").count
    }
  end
end
