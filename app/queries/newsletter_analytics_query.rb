class NewsletterAnalyticsQuery
  def initialize(newsletter)
    @newsletter = newsletter
    @deliveries = newsletter.newsletter_deliveries
  end

  def deliveries_count
    @deliveries.count
  end

  def opens_count
    @deliveries.where.not(opened_at: nil).count
  end

  def clicks_count
    @deliveries.where.not(clicked_at: nil).count
  end

  def bounces_count
    @deliveries.where.not(bounced_at: nil).count
  end

  def open_rate
    return 0.0 if deliveries_count.zero?
    (opens_count.to_f / deliveries_count * 100).round(1)
  end

  def click_rate
    return 0.0 if deliveries_count.zero?
    (clicks_count.to_f / deliveries_count * 100).round(1)
  end

  def bounce_rate
    return 0.0 if deliveries_count.zero?
    (bounces_count.to_f / deliveries_count * 100).round(1)
  end
end
