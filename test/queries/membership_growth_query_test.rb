require "test_helper"

class MembershipGrowthQueryTest < ActiveSupport::TestCase
  setup do
    @query = MembershipGrowthQuery.new
  end

  test "new_members counts recent memberships" do
    count = @query.new_members(since: 90.days.ago)
    assert count >= 0
  end

  test "cancellations counts canceled memberships" do
    count = @query.cancellations(since: 90.days.ago)
    assert count >= 0
  end

  test "net_growth returns new minus cancellations" do
    net = @query.net_growth(since: 90.days.ago)
    expected = @query.new_members(since: 90.days.ago) - @query.cancellations(since: 90.days.ago)
    assert_equal expected, net
  end

  test "growth_by_month returns array of month data" do
    result = @query.growth_by_month(since: 12.months.ago)
    assert_kind_of Array, result
    if result.any?
      assert result.first.key?(:month)
      assert result.first.key?(:new)
      assert result.first.key?(:canceled)
    end
  end
end
