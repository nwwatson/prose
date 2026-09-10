require "test_helper"

class MembershipTierTest < ActiveSupport::TestCase
  test "valid tier" do
    tier = MembershipTier.new(name: "Basic", price_cents: 500, currency: "usd", interval: :month)
    assert tier.valid?
  end

  test "requires name" do
    tier = MembershipTier.new(price_cents: 500)
    assert_not tier.valid?
    assert tier.errors[:name].any?
  end

  test "requires price_cents" do
    tier = MembershipTier.new(name: "Basic")
    assert_not tier.valid?
    assert tier.errors[:price_cents].any?
  end

  test "price_cents must be positive" do
    tier = MembershipTier.new(name: "Basic", price_cents: 0)
    assert_not tier.valid?
  end

  test "active scope" do
    active = MembershipTier.active
    assert active.include?(membership_tiers(:monthly))
    assert_not active.include?(membership_tiers(:inactive))
  end

  test "ordered scope" do
    tiers = MembershipTier.ordered
    assert_equal membership_tiers(:monthly), tiers.first
  end

  test "price_in_dollars" do
    tier = membership_tiers(:monthly)
    assert_equal 10.0, tier.price_in_dollars
  end

  test "formatted_price" do
    tier = membership_tiers(:monthly)
    assert_equal "$10.00", tier.formatted_price
  end

  test "interval_label" do
    assert_equal "/mo", membership_tiers(:monthly).interval_label
    assert_equal "/yr", membership_tiers(:annual).interval_label
  end

  test "current_member_counts returns a hash of current member counts keyed by tier id" do
    counts = MembershipTier.current_member_counts
    assert_equal 1, counts[membership_tiers(:monthly).id]
  end

  test "current_member_counts excludes canceled memberships" do
    counts = MembershipTier.current_member_counts
    assert_equal 0, counts.fetch(membership_tiers(:annual).id, 0)
  end
end
