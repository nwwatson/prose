require "test_helper"

class ReferrerAnalyticsQueryTest < ActiveSupport::TestCase
  setup do
    @query = ReferrerAnalyticsQuery.new
  end

  test "top_domains returns domains ordered by count" do
    result = @query.top_domains(since: 30.days.ago)
    assert_kind_of Hash, result
    assert result.values.all? { |v| v.is_a?(Integer) }
    # Values should be descending
    values = result.values
    values.each_cons(2) { |a, b| assert a >= b }
  end

  test "top_domains excludes nil domains" do
    result = @query.top_domains(since: 30.days.ago)
    assert_not result.key?(nil)
  end

  test "top_domains respects limit" do
    result = @query.top_domains(limit: 2, since: 30.days.ago)
    assert result.size <= 2
  end

  test "utm_sources returns sources from views with utm_source" do
    result = @query.utm_sources(since: 30.days.ago)
    assert_kind_of Hash, result
    result.each do |source, count|
      assert_not_nil source
      assert count.positive?
    end
  end

  test "utm_mediums returns mediums" do
    result = @query.utm_mediums(since: 30.days.ago)
    assert_kind_of Hash, result
  end

  test "utm_campaigns returns campaigns" do
    result = @query.utm_campaigns(since: 30.days.ago)
    assert_kind_of Hash, result
    assert result.key?("spring_sale") || result.key?("weekly_digest")
  end

  test "campaign_detail returns breakdown for a campaign" do
    result = @query.campaign_detail("spring_sale", since: 90.days.ago)
    assert_kind_of Hash, result
    assert result.key?(:total_views)
    assert result.key?(:sources)
    assert result.key?(:mediums)
    assert result[:total_views].is_a?(Integer)
  end
end
