class NewsletterAnalyticsQuery
  include TimeBucketing

  def initialize(newsletter)
    @newsletter = newsletter
    @deliveries = newsletter.newsletter_deliveries
  end

  def deliveries_count
    counts[0]
  end

  def opens_count
    counts[1]
  end

  def clicks_count
    counts[2]
  end

  def bounces_count
    counts[3]
  end

  def open_rate
    percentage(opens_count, deliveries_count)
  end

  def click_rate
    percentage(clicks_count, deliveries_count)
  end

  def bounce_rate
    percentage(bounces_count, deliveries_count)
  end

  private

  # All four totals in one query; COUNT(column) skips NULLs.
  def counts
    @counts ||= @deliveries.pick(
      Arel.sql("COUNT(*)"), Arel.sql("COUNT(opened_at)"), Arel.sql("COUNT(clicked_at)"), Arel.sql("COUNT(bounced_at)")
    )
  end
end
