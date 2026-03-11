require "test_helper"

class PostViewsQueryTest < ActiveSupport::TestCase
  setup do
    @query = PostViewsQuery.new
  end

  test "total_views returns count" do
    assert @query.total_views.is_a?(Integer)
    assert @query.total_views >= 0
  end

  test "total_views with since filters by date" do
    all_count = @query.total_views
    recent_count = @query.total_views(since: 30.days.ago)
    assert recent_count <= all_count
  end

  test "views_by_day returns hash of date strings to counts" do
    result = @query.views_by_day(since: 30.days.ago)
    assert_kind_of Hash, result
    result.each do |date, count|
      assert_match(/\A\d{4}-\d{2}-\d{2}\z/, date)
      assert count.is_a?(Integer)
    end
  end

  test "traffic_sources returns hash of sources to counts" do
    result = @query.traffic_sources(since: 30.days.ago)
    assert_kind_of Hash, result
  end

  test "top_posts returns posts with views_count" do
    result = @query.top_posts(limit: 5, since: 90.days.ago)
    result.each do |post|
      assert post.respond_to?(:views_count)
    end
  end

  test "unique_viewers returns distinct ip_hash count" do
    result = @query.unique_viewers(since: 30.days.ago)
    assert result.is_a?(Integer)
    assert result >= 0
  end

  test "trend_comparison returns current, previous, and change for week" do
    result = @query.trend_comparison(period: :week)
    assert result.key?(:current)
    assert result.key?(:previous)
    assert result.key?(:change)
    assert result[:current].is_a?(Integer)
    assert result[:previous].is_a?(Integer)
    assert result[:change].is_a?(Float) || result[:change].is_a?(Integer)
  end

  test "trend_comparison returns data for month" do
    result = @query.trend_comparison(period: :month)
    assert result.key?(:current)
    assert result.key?(:previous)
    assert result.key?(:change)
  end

  test "trend_comparison raises for invalid period" do
    assert_raises(ArgumentError) do
      @query.trend_comparison(period: :year)
    end
  end

  test "top_posts_by_engagement returns posts with engagement data" do
    result = @query.top_posts_by_engagement(limit: 5, since: 90.days.ago)
    result.each do |post|
      assert post.respond_to?(:views_count)
      assert post.respond_to?(:unique_viewers_count)
    end
  end
end
