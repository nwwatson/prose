require "test_helper"

class AnalyticsRangeTest < ActiveSupport::TestCase
  test "parse returns the requested range when allowed" do
    range = AnalyticsRange.parse("7d", default: "30d", allowed: %w[7d 30d 90d all])
    assert_equal "7d", range.key
  end

  test "parse falls back to the default when the param is not allowed" do
    range = AnalyticsRange.parse("bogus", default: "30d", allowed: %w[7d 30d 90d all])
    assert_equal "30d", range.key
  end

  test "parse falls back to the default when the param is nil" do
    range = AnalyticsRange.parse(nil, default: "12mo", allowed: %w[6mo 12mo 24mo all])
    assert_equal "12mo", range.key
  end

  test "since resolves 7d" do
    assert_in_delta 7.days.ago, AnalyticsRange.new("7d").since, 5.seconds
  end

  test "since resolves 30d" do
    assert_in_delta 30.days.ago, AnalyticsRange.new("30d").since, 5.seconds
  end

  test "since resolves 90d" do
    assert_in_delta 90.days.ago, AnalyticsRange.new("90d").since, 5.seconds
  end

  test "since resolves 6mo" do
    assert_in_delta 6.months.ago, AnalyticsRange.new("6mo").since, 5.seconds
  end

  test "since resolves 12mo" do
    assert_in_delta 12.months.ago, AnalyticsRange.new("12mo").since, 5.seconds
  end

  test "since resolves 24mo" do
    assert_in_delta 24.months.ago, AnalyticsRange.new("24mo").since, 5.seconds
  end

  test "since resolves all to the epoch" do
    assert_equal Time.at(0), AnalyticsRange.new("all").since
  end

  test "label upcases the key" do
    assert_equal "7D", AnalyticsRange.new("7d").label
  end

  test "equality compares by key" do
    assert_equal AnalyticsRange.new("7d"), AnalyticsRange.new("7d")
    assert_not_equal AnalyticsRange.new("7d"), AnalyticsRange.new("30d")
  end
end
