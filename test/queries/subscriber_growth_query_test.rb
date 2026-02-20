require "test_helper"

class SubscriberGrowthQueryTest < ActiveSupport::TestCase
  setup do
    @query = SubscriberGrowthQuery.new
  end

  test "total returns count of confirmed subscribers" do
    confirmed_count = Subscriber.confirmed.count
    assert_equal confirmed_count, @query.total
  end

  test "growth_by_month returns monthly counts" do
    result = @query.growth_by_month(since: 1.year.ago)
    assert_kind_of Hash, result
    result.each do |key, value|
      assert_match(/\A\d{4}-\d{2}\z/, key)
      assert_kind_of Integer, value
    end
  end

  test "cumulative_by_month returns running totals" do
    result = @query.cumulative_by_month(since: 1.year.ago)
    assert_kind_of Hash, result

    values = result.values
    values.each_cons(2) do |a, b|
      assert b >= a, "Cumulative values should be non-decreasing: #{a} -> #{b}"
    end
  end

  test "cumulative_by_month includes baseline from before range" do
    # All confirmed subscribers should be accounted for
    result = @query.cumulative_by_month(since: 1.year.ago)
    if result.any?
      assert result.values.last <= @query.total
    end
  end

  test "top_posts_by_subscribers returns posts with subscriber counts" do
    result = @query.top_posts_by_subscribers(limit: 5)
    assert_kind_of ActiveRecord::Relation, result
    result.each do |post|
      assert post.respond_to?(:subscribers_count)
      assert post.subscribers_count.positive?
    end
  end

  test "top_posts_by_subscribers respects limit" do
    result = @query.top_posts_by_subscribers(limit: 1).to_a
    assert result.length <= 1
  end

  test "most_recent_post_subscribers returns post and count" do
    result = @query.most_recent_post_subscribers
    if Post.published.any?
      assert_not_nil result
      assert_kind_of Post, result[:post]
      assert_kind_of Integer, result[:count]
    end
  end

  test "most_recent_post_subscribers returns nil when no published posts" do
    Post.update_all(status: :draft)
    result = @query.most_recent_post_subscribers
    assert_nil result
  end
end
