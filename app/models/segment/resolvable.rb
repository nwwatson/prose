module Segment::Resolvable
  extend ActiveSupport::Concern

  def resolve(scope = Subscriber.confirmed)
    SegmentSubscribersQuery.new(filter_criteria, scope: scope).resolve
  end

  def subscriber_count
    @subscriber_count ||= resolve.count
  end
end
