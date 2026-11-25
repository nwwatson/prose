require "test_helper"

class Segment::CriteriaBuilderTest < ActiveSupport::TestCase
  test "builds every criterion from the flat form attributes" do
    segment = Segment.new(
      name: "All",
      label_ids: [ "", subscriber_labels(:vip).id.to_s, subscriber_labels(:beta_tester).id.to_s ],
      label_mode: "all_of",
      subscribed_after: "2026-01-01",
      subscribed_before: "2026-06-30",
      engagement: "inactive"
    )
    segment.validate

    assert_equal(
      {
        labels: { ids: [ subscriber_labels(:vip).id, subscriber_labels(:beta_tester).id ], mode: "all_of" },
        subscribed_after: "2026-01-01",
        subscribed_before: "2026-06-30",
        engagement: "inactive"
      },
      segment.filter_criteria.deep_symbolize_keys
    )
  end

  test "round-trips through save and reload" do
    segment = Segment.create!(name: "VIP", label_ids: [ subscriber_labels(:vip).id.to_s ], engagement: "active")
    reloaded = Segment.find(segment.id)

    assert_equal [ subscriber_labels(:vip).id ], reloaded.label_ids
    assert_equal "any_of", reloaded.label_mode
    assert_equal "active", reloaded.engagement
    assert_nil reloaded.subscribed_after
  end

  test "submitting the form with every field blank clears the stored criteria" do
    segment = segments(:vip_segment)
    segment.update!(label_ids: [ "" ], label_mode: "", subscribed_after: "", subscribed_before: "", engagement: "")

    assert_equal({}, segment.reload.filter_criteria)
  end

  test "readers fall back to the stored criteria until a form value is assigned" do
    segment = segments(:engaged_segment)
    assert_equal "active", segment.engagement

    segment.engagement = "inactive"
    assert_equal "inactive", segment.engagement
  end

  test "saving without form values keeps the stored criteria" do
    segment = segments(:vip_segment)
    stored = segment.filter_criteria

    segment.update!(name: "New name")

    assert_equal stored, segment.reload.filter_criteria
  end

  test "criteria assigned directly are saved as given" do
    segment = Segment.create!(name: "Direct", filter_criteria: { engagement: "inactive" })

    assert_equal({ "engagement" => "inactive" }, segment.reload.filter_criteria)
  end

  test "assigning one form value keeps the other stored criteria" do
    segment = segments(:vip_segment)

    segment.update!(engagement: "active")
    assert_equal [ subscriber_labels(:vip).id ], segment.reload.label_ids
    assert_equal "active", segment.engagement

    segment.update!(label_mode: "none_of")
    assert_equal [ subscriber_labels(:vip).id ], segment.reload.label_ids
    assert_equal "none_of", segment.label_mode
    assert_equal "active", segment.engagement
  end

  test "a later save does not reapply form values already saved" do
    segment = Segment.create!(name: "Once", engagement: "active")

    segment.update!(filter_criteria: { engagement: "inactive" })

    assert_equal({ "engagement" => "inactive" }, segment.reload.filter_criteria)
  end

  test "label_mode defaults to any_of" do
    assert_equal "any_of", Segment.new.label_mode
  end
end
