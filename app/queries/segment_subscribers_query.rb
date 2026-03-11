class SegmentSubscribersQuery
  def initialize(criteria = {})
    @criteria = criteria.deep_symbolize_keys
  end

  def resolve
    scope = Subscriber.confirmed

    scope = apply_label_filters(scope)
    scope = apply_date_filters(scope)
    scope = apply_engagement_filter(scope)

    scope
  end

  private

  def apply_label_filters(scope)
    if @criteria[:labels].present?
      label_ids = @criteria[:labels][:ids]
      mode = @criteria[:labels][:mode] || "any_of"

      return scope if label_ids.blank?

      case mode
      when "any_of"
        scope.where(id: SubscriberLabeling.where(subscriber_label_id: label_ids).select(:subscriber_id))
      when "all_of"
        label_ids.each do |label_id|
          scope = scope.where(id: SubscriberLabeling.where(subscriber_label_id: label_id).select(:subscriber_id))
        end
        scope
      when "none_of"
        scope.where.not(id: SubscriberLabeling.where(subscriber_label_id: label_ids).select(:subscriber_id))
      else
        scope
      end
    else
      scope
    end
  end

  def apply_date_filters(scope)
    if @criteria[:subscribed_after].present?
      scope = scope.where("confirmed_at >= ?", Time.zone.parse(@criteria[:subscribed_after].to_s))
    end

    if @criteria[:subscribed_before].present?
      scope = scope.where("confirmed_at <= ?", Time.zone.parse(@criteria[:subscribed_before].to_s))
    end

    scope
  end

  def apply_engagement_filter(scope)
    return scope if @criteria[:engagement].blank?

    case @criteria[:engagement]
    when "active"
      scope.where(id: engaged_subscriber_ids)
    when "inactive"
      scope.where.not(id: engaged_subscriber_ids)
    else
      scope
    end
  end

  def engaged_subscriber_ids
    NewsletterDelivery
      .where("opened_at IS NOT NULL OR clicked_at IS NOT NULL")
      .where("sent_at >= ?", 90.days.ago)
      .select(:subscriber_id)
  end
end
