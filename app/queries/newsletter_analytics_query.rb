class NewsletterAnalyticsQuery
  include TimeBucketing

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
    percentage(opens_count, deliveries_count)
  end

  def click_rate
    percentage(clicks_count, deliveries_count)
  end

  def bounce_rate
    percentage(bounces_count, deliveries_count)
  end
end
