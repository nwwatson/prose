require "test_helper"

class SegmentSubscribersQueryTest < ActiveSupport::TestCase
  test "returns all confirmed subscribers with empty criteria" do
    result = SegmentSubscribersQuery.new({}).resolve
    assert_equal Subscriber.confirmed.count, result.count
  end

  test "filters by any_of labels" do
    vip = subscriber_labels(:vip)
    criteria = { labels: { ids: [ vip.id ], mode: "any_of" } }
    result = SegmentSubscribersQuery.new(criteria).resolve

    assert_includes result, subscribers(:confirmed)
    assert_includes result, subscribers(:with_token)
    assert_not_includes result, subscribers(:from_published_post)
  end

  test "filters by all_of labels" do
    vip = subscriber_labels(:vip)
    beta = subscriber_labels(:beta_tester)
    criteria = { labels: { ids: [ vip.id, beta.id ], mode: "all_of" } }
    result = SegmentSubscribersQuery.new(criteria).resolve

    # Only confirmed has both VIP and Beta Tester
    assert_includes result, subscribers(:confirmed)
    assert_not_includes result, subscribers(:with_token)
  end

  test "filters by none_of labels" do
    vip = subscriber_labels(:vip)
    criteria = { labels: { ids: [ vip.id ], mode: "none_of" } }
    result = SegmentSubscribersQuery.new(criteria).resolve

    assert_not_includes result, subscribers(:confirmed)
    assert_not_includes result, subscribers(:with_token)
  end

  test "filters by subscribed_after date" do
    criteria = { subscribed_after: 5.days.ago.to_date.to_s }
    result = SegmentSubscribersQuery.new(criteria).resolve

    # from_published_post confirmed 3 days ago, from_featured_post 2 days ago
    assert_includes result, subscribers(:from_published_post)
    assert_includes result, subscribers(:from_featured_post)
  end

  test "filters by subscribed_before date" do
    criteria = { subscribed_before: 5.days.ago.to_date.to_s }
    result = SegmentSubscribersQuery.new(criteria).resolve

    # confirmed and with_token confirmed 1 week ago
    assert_includes result, subscribers(:confirmed)
  end

  test "filters by active engagement" do
    criteria = { engagement: "active" }
    result = SegmentSubscribersQuery.new(criteria).resolve

    # opened_delivery and clicked_delivery have engagement
    assert_includes result, subscribers(:with_token)
    assert_includes result, subscribers(:from_published_post)
  end

  test "filters by inactive engagement" do
    criteria = { engagement: "inactive" }
    result = SegmentSubscribersQuery.new(criteria).resolve

    assert_not_includes result, subscribers(:with_token)
    assert_not_includes result, subscribers(:from_published_post)
  end

  test "combines multiple filters" do
    vip = subscriber_labels(:vip)
    criteria = {
      labels: { ids: [ vip.id ], mode: "any_of" },
      engagement: "active"
    }
    result = SegmentSubscribersQuery.new(criteria).resolve

    # with_token is VIP and has opened_delivery
    assert_includes result, subscribers(:with_token)
    # confirmed is VIP but has no opens/clicks (sent_to_confirmed has no opened_at)
    assert_not_includes result, subscribers(:confirmed)
  end

  test "always scopes to confirmed subscribers" do
    criteria = {}
    result = SegmentSubscribersQuery.new(criteria).resolve

    assert_not_includes result, subscribers(:unconfirmed)
  end
end
