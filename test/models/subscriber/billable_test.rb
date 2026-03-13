require "test_helper"

class Subscriber::BillableTest < ActiveSupport::TestCase
  test "active_membership returns current membership" do
    subscriber = subscribers(:confirmed)
    assert_equal memberships(:active_membership), subscriber.active_membership
  end

  test "active_membership returns nil when no current membership" do
    subscriber = subscribers(:unconfirmed)
    assert_nil subscriber.active_membership
  end

  test "paid_member? returns true for subscriber with active membership" do
    assert subscribers(:confirmed).paid_member?
  end

  test "paid_member? returns false for subscriber without membership" do
    assert_not subscribers(:unconfirmed).paid_member?
  end

  test "free_member? returns true for confirmed subscriber without membership" do
    subscriber = subscribers(:with_token)
    assert subscriber.free_member?
  end

  test "free_member? returns false for paid member" do
    assert_not subscribers(:confirmed).free_member?
  end

  test "stripe_customer_id returns most recent customer id" do
    subscriber = subscribers(:confirmed)
    assert_equal "cus_active_test", subscriber.stripe_customer_id
  end
end
