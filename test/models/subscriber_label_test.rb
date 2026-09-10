require "test_helper"

class SubscriberLabelTest < ActiveSupport::TestCase
  test "valid with name and color" do
    label = SubscriberLabel.new(name: "New Label", color: "#FF0000")
    assert label.valid?
  end

  test "requires name" do
    label = SubscriberLabel.new(color: "#FF0000")
    assert_not label.valid?
    assert label.errors[:name].any?
  end

  test "requires unique name" do
    label = SubscriberLabel.new(name: subscriber_labels(:vip).name, color: "#FF0000")
    assert_not label.valid?
    assert label.errors[:name].any?
  end

  test "requires valid hex color" do
    label = SubscriberLabel.new(name: "Test", color: "not-a-color")
    assert_not label.valid?
    assert label.errors[:color].any?
  end

  test "accepts valid hex colors" do
    label = SubscriberLabel.new(name: "Test", color: "#aaBB00")
    assert label.valid?
  end

  test "has many subscribers through labelings" do
    label = subscriber_labels(:vip)
    assert_includes label.subscribers, subscribers(:confirmed)
  end

  test "destroying label destroys labelings" do
    label = subscriber_labels(:vip)
    assert_difference "SubscriberLabeling.count", -label.subscriber_labelings.count do
      label.destroy
    end
  end

  test "subscriber_counts returns a hash of subscriber counts keyed by label id" do
    counts = SubscriberLabel.subscriber_counts
    assert_equal subscriber_labels(:vip).subscribers.count, counts[subscriber_labels(:vip).id]
    assert_equal subscriber_labels(:beta_tester).subscribers.count, counts[subscriber_labels(:beta_tester).id]
  end

  test "subscriber_counts is zero for a label with no subscribers" do
    empty_label = SubscriberLabel.create!(name: "Empty", color: "#123456")
    counts = SubscriberLabel.subscriber_counts
    assert_equal 0, counts.fetch(empty_label.id, 0)
  end
end
