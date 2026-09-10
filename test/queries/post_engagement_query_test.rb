require "test_helper"

class PostEngagementQueryTest < ActiveSupport::TestCase
  setup do
    @post = posts(:published_post)
    @query = PostEngagementQuery.new(@post)
  end

  test "views_count returns total post views" do
    assert_equal @post.post_views.count, @query.views_count
  end

  test "views_count with since filters by date" do
    expected = @post.post_views.since(30.days.ago).count
    assert_equal expected, @query.views_count(since: 30.days.ago)
  end

  test "unique_viewers returns distinct ip_hash count" do
    expected = @post.post_views.distinct.count(:ip_hash)
    assert_equal expected, @query.unique_viewers
  end

  test "loves_count returns the post's loves_count" do
    assert_equal @post.loves_count, @query.loves_count
  end

  test "comments_count returns approved comments count" do
    assert_equal @post.comments.approved.count, @query.comments_count
  end

  test "engagement_rate calculates percentage of loves and comments over views" do
    views = @query.views_count
    expected = (views.zero? ? 0.0 : ((@query.loves_count + @query.comments_count).to_f / views * 100).round(1))
    assert_equal expected, @query.engagement_rate
  end

  test "engagement_rate returns 0.0 when there are no views" do
    post = posts(:draft_post)
    query = PostEngagementQuery.new(post)
    assert_equal 0.0, query.engagement_rate
  end

  test "traffic_sources returns hash of sources to counts" do
    result = @query.traffic_sources(since: 30.days.ago)
    assert_kind_of Hash, result
    assert_equal @post.post_views.since(30.days.ago).group(:source).count.values.sum, result.values.sum
  end

  test "views_by_day returns hash of date strings to counts" do
    result = @query.views_by_day(since: 30.days.ago)
    assert_kind_of Hash, result
    result.each do |date, count|
      assert_match(/\A\d{4}-\d{2}-\d{2}\z/, date)
      assert_kind_of Integer, count
    end
  end
end
