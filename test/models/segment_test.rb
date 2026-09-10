require "test_helper"

class SegmentTest < ActiveSupport::TestCase
  test "valid with name" do
    segment = Segment.new(name: "Test Segment")
    assert segment.valid?
  end

  test "requires name" do
    segment = Segment.new
    assert_not segment.valid?
    assert segment.errors[:name].any?
  end

  test "resolve returns subscribers matching criteria" do
    segment = segments(:vip_segment)
    result = segment.resolve
    assert_kind_of ActiveRecord::Relation, result
  end

  test "subscriber_count returns count of matching subscribers" do
    segment = segments(:vip_segment)
    assert_kind_of Integer, segment.subscriber_count
  end

  test "subscriber_count memoizes the resolved count" do
    segment = segments(:vip_segment)

    resolve_calls = 0
    segment.define_singleton_method(:resolve) do
      resolve_calls += 1
      SegmentSubscribersQuery.new(filter_criteria).resolve
    end

    3.times { segment.subscriber_count }
    assert_equal 1, resolve_calls
  end

  test "nullifies newsletters on destroy" do
    segment = segments(:vip_segment)
    newsletter = newsletters(:draft_newsletter)
    newsletter.update!(segment: segment)

    segment.destroy
    assert_nil newsletter.reload.segment_id
  end
end
