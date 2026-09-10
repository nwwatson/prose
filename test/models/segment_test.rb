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

    query_count = 0
    callback = lambda do |*, payload|
      query_count += 1 if payload[:sql].match?(/FROM "subscribers"/)
    end

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      segment.subscriber_count
      segment.subscriber_count
    end

    assert_equal 1, query_count
  end

  test "nullifies newsletters on destroy" do
    segment = segments(:vip_segment)
    newsletter = newsletters(:draft_newsletter)
    newsletter.update!(segment: segment)

    segment.destroy
    assert_nil newsletter.reload.segment_id
  end

  test "builds filter_criteria from label attributes" do
    label = subscriber_labels(:vip)
    segment = Segment.new(name: "Test", label_ids: [ label.id.to_s, "" ], label_mode: "all_of")

    segment.valid?

    assert_equal({ "labels" => { "ids" => [ label.id ], "mode" => "all_of" } }, segment.filter_criteria)
  end

  test "defaults label_mode to any_of when labels are present without a mode" do
    label = subscriber_labels(:vip)
    segment = Segment.new(name: "Test", label_ids: [ label.id.to_s ])

    segment.valid?

    assert_equal "any_of", segment.filter_criteria["labels"]["mode"]
  end

  test "omits labels from filter_criteria when no ids are given" do
    segment = Segment.new(name: "Test", label_ids: [ "" ], label_mode: "all_of")

    segment.valid?

    assert_not segment.filter_criteria.key?("labels")
  end

  test "builds filter_criteria from date and engagement attributes" do
    segment = Segment.new(name: "Test", subscribed_after: "2024-01-01", subscribed_before: "2024-06-01", engagement: "active")

    segment.valid?

    assert_equal({
      "subscribed_after" => "2024-01-01",
      "subscribed_before" => "2024-06-01",
      "engagement" => "active"
    }, segment.filter_criteria)
  end

  test "omits blank date and engagement attributes from filter_criteria" do
    segment = Segment.new(name: "Test")

    segment.valid?

    assert_equal({}, segment.filter_criteria)
  end

  test "label_ids reads back from stored filter_criteria" do
    segment = segments(:vip_segment)
    assert_equal [ subscriber_labels(:vip).id ], segment.label_ids
  end

  test "label_mode reads back from stored filter_criteria" do
    segment = segments(:vip_segment)
    assert_equal "any_of", segment.label_mode
  end

  test "subscribed_after reads back from stored filter_criteria" do
    segment = segments(:recent_segment)
    assert_equal segment.filter_criteria["subscribed_after"], segment.subscribed_after
  end

  test "engagement reads back from stored filter_criteria" do
    segment = segments(:engaged_segment)
    assert_equal "active", segment.engagement
  end

  test "label_ids returns empty array when no labels are set" do
    segment = segments(:engaged_segment)
    assert_equal [], segment.label_ids
  end
end
