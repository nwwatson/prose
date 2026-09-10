# Value object resolving an admin analytics "range" param (e.g. "7d", "30d", "all")
# into a `since` timestamp, shared by TrafficController, RevenueController,
# GrowthController, and Admin::AnalyticsRangeable.
class AnalyticsRange
  PRESETS = {
    "7d" => -> { 7.days.ago },
    "30d" => -> { 30.days.ago },
    "90d" => -> { 90.days.ago },
    "6mo" => -> { 6.months.ago },
    "12mo" => -> { 12.months.ago },
    "24mo" => -> { 24.months.ago },
    "all" => -> { Time.at(0) }
  }.freeze

  attr_reader :key

  def self.parse(param, default:, allowed:)
    new(allowed.include?(param) ? param : default)
  end

  def initialize(key)
    @key = key
  end

  def since
    PRESETS.fetch(key).call
  end

  def label
    key.upcase
  end

  def ==(other)
    other.is_a?(AnalyticsRange) && key == other.key
  end
end
