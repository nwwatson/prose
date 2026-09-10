require "test_helper"
require "ostruct"

class SyncStripeSubscriptionJobTest < ActiveJob::TestCase
  test "does nothing when payments are not configured" do
    membership = memberships(:active_membership)
    original_status = membership.status

    SyncStripeSubscriptionJob.perform_now

    assert_equal original_status, membership.reload.status
  end

  test "syncs current memberships from Stripe" do
    SiteSetting.current.update!(stripe_secret_key: "sk_test", stripe_publishable_key: "pk_test")

    membership = memberships(:active_membership)
    period_start = 1.day.ago.to_i
    period_end = 29.days.from_now.to_i
    mock_subscription = OpenStruct.new(
      status: "past_due",
      current_period_start: period_start,
      current_period_end: period_end,
      canceled_at: nil
    )

    PaymentService::Stripe.define_method(:retrieve_subscription) { |_id| mock_subscription }

    SyncStripeSubscriptionJob.perform_now

    membership.reload
    assert membership.past_due?
    assert_equal Time.at(period_start).to_i, membership.current_period_start.to_i
    assert_equal Time.at(period_end).to_i, membership.current_period_end.to_i
  ensure
    SiteSetting.current.update!(stripe_secret_key: nil, stripe_publishable_key: nil)
    PaymentService::Stripe.remove_method(:retrieve_subscription) if PaymentService::Stripe.method_defined?(:retrieve_subscription, false)
  end

  test "logs and continues when a membership fails to sync" do
    SiteSetting.current.update!(stripe_secret_key: "sk_test", stripe_publishable_key: "pk_test")

    PaymentService::Stripe.define_method(:retrieve_subscription) { |_id| raise "boom" }

    assert_nothing_raised do
      SyncStripeSubscriptionJob.perform_now
    end
  ensure
    SiteSetting.current.update!(stripe_secret_key: nil, stripe_publishable_key: nil)
    PaymentService::Stripe.remove_method(:retrieve_subscription) if PaymentService::Stripe.method_defined?(:retrieve_subscription, false)
  end
end
