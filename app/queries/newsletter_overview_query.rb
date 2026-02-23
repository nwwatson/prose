class NewsletterOverviewQuery
  def total_sent(since: nil)
    scope = Newsletter.sent
    scope = scope.where("sent_at >= ?", since) if since
    scope.count
  end

  def total_deliveries(since: nil)
    scope = Newsletter.sent
    scope = scope.where("sent_at >= ?", since) if since
    scope.sum(:recipients_count)
  end

  def average_open_rate(since: nil)
    scope = Newsletter.sent.joins(:newsletter_deliveries)
    scope = scope.where("newsletters.sent_at >= ?", since) if since

    total = scope.count("newsletter_deliveries.id")
    opened = scope.where.not(newsletter_deliveries: { opened_at: nil }).count("newsletter_deliveries.id")

    return 0.0 if total.zero?
    (opened.to_f / total * 100).round(1)
  end

  def recent_newsletters(limit: 5)
    Newsletter.sent.order(sent_at: :desc).limit(limit)
  end
end
