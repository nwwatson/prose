require "test_helper"
require "ostruct"

class StripeWebhookJobTest < ActiveJob::TestCase
  test "handles checkout.session.completed" do
    SiteSetting.current.update!(stripe_secret_key: "sk_test", stripe_publishable_key: "pk_test")

    tier = membership_tiers(:monthly)
    subscriber = subscribers(:with_token)

    mock_item = OpenStruct.new(price: OpenStruct.new(id: tier.stripe_price_id))
    mock_subscription = OpenStruct.new(
      status: "active",
      items: OpenStruct.new(data: [ mock_item ]),
      current_period_start: Time.current.to_i,
      current_period_end: 30.days.from_now.to_i
    )

    event_data = {
      "mode" => "subscription",
      "customer_details" => { "email" => subscriber.email },
      "subscription" => "sub_new_checkout_test",
      "customer" => "cus_new_checkout_test"
    }

    PaymentService::Stripe.define_method(:retrieve_subscription) { |_id| mock_subscription }

    assert_difference "Membership.count", 1 do
      StripeWebhookJob.perform_now("checkout.session.completed", event_data)
    end

    membership = Membership.find_by(stripe_subscription_id: "sub_new_checkout_test")
    assert_equal subscriber, membership.subscriber
    assert_equal tier, membership.membership_tier
    assert membership.active?
  ensure
    SiteSetting.current.update!(stripe_secret_key: nil, stripe_publishable_key: nil)
    PaymentService::Stripe.remove_method(:retrieve_subscription) if PaymentService::Stripe.method_defined?(:retrieve_subscription, false)
  end

  test "handles customer.subscription.updated" do
    membership = memberships(:active_membership)
    event_data = {
      "id" => membership.stripe_subscription_id,
      "status" => "past_due",
      "current_period_start" => Time.current.to_i,
      "current_period_end" => 30.days.from_now.to_i,
      "canceled_at" => nil
    }

    StripeWebhookJob.perform_now("customer.subscription.updated", event_data)
    assert membership.reload.past_due?
  end

  test "handles customer.subscription.deleted" do
    membership = memberships(:active_membership)
    event_data = { "id" => membership.stripe_subscription_id }

    StripeWebhookJob.perform_now("customer.subscription.deleted", event_data)
    assert membership.reload.canceled?
  end

  test "handles invoice.payment_failed" do
    membership = memberships(:active_membership)
    event_data = { "subscription" => membership.stripe_subscription_id }

    StripeWebhookJob.perform_now("invoice.payment_failed", event_data)
    assert membership.reload.past_due?
  end

  test "ignores unknown events" do
    assert_nothing_raised do
      StripeWebhookJob.perform_now("unknown.event", {})
    end
  end
end
