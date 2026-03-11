module Segment::Resolvable
  extend ActiveSupport::Concern

  def resolve
    SegmentSubscribersQuery.new(filter_criteria).resolve
  end

  def subscriber_count
    resolve.count
  end
end
