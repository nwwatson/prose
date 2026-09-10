require "test_helper"
require "ostruct"

class Membership::StripeSyncableTest < ActiveSupport::TestCase
  test "status_from_stripe maps known statuses" do
    assert_equal :active, Membership.status_from_stripe("active")
    assert_equal :past_due, Membership.status_from_stripe("past_due")
    assert_equal :canceled, Membership.status_from_stripe("canceled")
    assert_equal :trialing, Membership.status_from_stripe("trialing")
  end

  test "status_from_stripe defaults unknown statuses to incomplete" do
    assert_equal :incomplete, Membership.status_from_stripe("unknown_status")
    assert_equal :incomplete, Membership.status_from_stripe(nil)
  end

  test "sync_from_stripe! updates status and periods from a Hash payload" do
    membership = memberships(:active_membership)
    period_start = 1.day.ago.to_i
    period_end = 29.days.from_now.to_i

    membership.sync_from_stripe!(
      "status" => "past_due",
      "current_period_start" => period_start,
      "current_period_end" => period_end,
      "canceled_at" => nil
    )

    membership.reload
    assert membership.past_due?
    assert_equal Time.at(period_start).to_i, membership.current_period_start.to_i
    assert_equal Time.at(period_end).to_i, membership.current_period_end.to_i
    assert_nil membership.canceled_at
  end

  test "sync_from_stripe! updates status and periods from a Stripe-like object" do
    membership = memberships(:active_membership)
    period_start = 1.day.ago.to_i
    period_end = 29.days.from_now.to_i
    canceled_at = 1.hour.ago.to_i

    subscription = OpenStruct.new(
      status: "canceled",
      current_period_start: period_start,
      current_period_end: period_end,
      canceled_at: canceled_at
    )

    membership.sync_from_stripe!(subscription)

    membership.reload
    assert membership.canceled?
    assert_equal Time.at(period_start).to_i, membership.current_period_start.to_i
    assert_equal Time.at(period_end).to_i, membership.current_period_end.to_i
    assert_equal Time.at(canceled_at).to_i, membership.canceled_at.to_i
  end

  test "sync_from_stripe! preserves existing period values when absent from the payload" do
    membership = memberships(:active_membership)
    original_start = membership.current_period_start
    original_end = membership.current_period_end

    membership.sync_from_stripe!("status" => "past_due", "canceled_at" => nil)

    membership.reload
    assert membership.past_due?
    assert_equal original_start.to_i, membership.current_period_start.to_i
    assert_equal original_end.to_i, membership.current_period_end.to_i
  end

  test "activate_from_checkout! creates a membership from session data and subscription" do
    tier = membership_tiers(:monthly)
    subscriber = subscribers(:unconfirmed)
    period_start = Time.current.to_i
    period_end = 30.days.from_now.to_i

    subscription = OpenStruct.new(
      status: "active",
      items: OpenStruct.new(data: [ OpenStruct.new(price: OpenStruct.new(id: tier.stripe_price_id)) ]),
      current_period_start: period_start,
      current_period_end: period_end,
      canceled_at: nil
    )

    session_data = {
      "mode" => "subscription",
      "customer_details" => { "email" => subscriber.email },
      "subscription" => "sub_activate_test",
      "customer" => "cus_activate_test"
    }

    assert_difference "Membership.count", 1 do
      Membership.activate_from_checkout!(session_data, subscription)
    end

    membership = Membership.find_by(stripe_subscription_id: "sub_activate_test")
    assert_equal subscriber, membership.subscriber
    assert_equal tier, membership.membership_tier
    assert_equal "cus_activate_test", membership.stripe_customer_id
    assert membership.active?
    assert_equal Time.at(period_start).to_i, membership.current_period_start.to_i
  end

  test "activate_from_checkout! is idempotent for repeated events" do
    tier = membership_tiers(:monthly)
    subscriber = subscribers(:unconfirmed)

    subscription = OpenStruct.new(
      status: "active",
      items: OpenStruct.new(data: [ OpenStruct.new(price: OpenStruct.new(id: tier.stripe_price_id)) ]),
      current_period_start: Time.current.to_i,
      current_period_end: 30.days.from_now.to_i,
      canceled_at: nil
    )

    session_data = {
      "mode" => "subscription",
      "customer_details" => { "email" => subscriber.email },
      "subscription" => "sub_idempotent_test",
      "customer" => "cus_idempotent_test"
    }

    Membership.activate_from_checkout!(session_data, subscription)

    assert_no_difference "Membership.count" do
      Membership.activate_from_checkout!(session_data, subscription)
    end
  end

  test "activate_from_checkout! returns nil when mode is not subscription" do
    session_data = { "mode" => "payment" }
    assert_no_difference "Membership.count" do
      assert_nil Membership.activate_from_checkout!(session_data, OpenStruct.new)
    end
  end

  test "activate_from_checkout! returns nil when subscriber is not found" do
    session_data = {
      "mode" => "subscription",
      "customer_details" => { "email" => "nobody@example.com" },
      "subscription" => "sub_missing_subscriber"
    }
    assert_no_difference "Membership.count" do
      assert_nil Membership.activate_from_checkout!(session_data, OpenStruct.new)
    end
  end

  test "activate_from_checkout! returns nil when tier is not found for the price" do
    subscriber = subscribers(:unconfirmed)
    subscription = OpenStruct.new(
      items: OpenStruct.new(data: [ OpenStruct.new(price: OpenStruct.new(id: "price_unknown")) ])
    )
    session_data = {
      "mode" => "subscription",
      "customer_details" => { "email" => subscriber.email },
      "subscription" => "sub_missing_tier"
    }

    assert_no_difference "Membership.count" do
      assert_nil Membership.activate_from_checkout!(session_data, subscription)
    end
  end
end
