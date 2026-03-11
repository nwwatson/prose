require "test_helper"

class SubscriberLabelingTest < ActiveSupport::TestCase
  test "valid with subscriber and label" do
    labeling = SubscriberLabeling.new(
      subscriber: subscribers(:unconfirmed),
      subscriber_label: subscriber_labels(:vip)
    )
    assert labeling.valid?
  end

  test "requires unique subscriber and label combination" do
    existing = subscriber_labelings(:confirmed_vip)
    duplicate = SubscriberLabeling.new(
      subscriber: existing.subscriber,
      subscriber_label: existing.subscriber_label
    )
    assert_not duplicate.valid?
  end

  test "belongs to subscriber" do
    labeling = subscriber_labelings(:confirmed_vip)
    assert_equal subscribers(:confirmed), labeling.subscriber
  end

  test "belongs to subscriber_label" do
    labeling = subscriber_labelings(:confirmed_vip)
    assert_equal subscriber_labels(:vip), labeling.subscriber_label
  end
end
