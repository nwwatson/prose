require "test_helper"
require "ostruct"

class SyncMembershipTierJobTest < ActiveJob::TestCase
  test "does nothing when payments are not configured" do
    tier = MembershipTier.create!(name: "Unsynced", price_cents: 500, currency: "usd", interval: :month)

    SyncMembershipTierJob.perform_now(tier)

    assert_nil tier.reload.stripe_product_id
    assert_nil tier.reload.stripe_price_id
  end

  test "creates a Stripe product and price and stores the ids" do
    SiteSetting.current.update!(stripe_secret_key: "sk_test", stripe_publishable_key: "pk_test")
    tier = MembershipTier.create!(name: "Unsynced", price_cents: 500, currency: "usd", interval: :month)

    mock_product = OpenStruct.new(id: "prod_new_test")
    mock_price = OpenStruct.new(id: "price_new_test")
    PaymentService::Stripe.define_method(:create_product) { |**_args| mock_product }
    PaymentService::Stripe.define_method(:create_price) { |**_args| mock_price }

    SyncMembershipTierJob.perform_now(tier)

    tier.reload
    assert_equal "prod_new_test", tier.stripe_product_id
    assert_equal "price_new_test", tier.stripe_price_id
  ensure
    SiteSetting.current.update!(stripe_secret_key: nil, stripe_publishable_key: nil)
    PaymentService::Stripe.remove_method(:create_product) if PaymentService::Stripe.method_defined?(:create_product, false)
    PaymentService::Stripe.remove_method(:create_price) if PaymentService::Stripe.method_defined?(:create_price, false)
  end

  test "only creates the price when the product already exists" do
    SiteSetting.current.update!(stripe_secret_key: "sk_test", stripe_publishable_key: "pk_test")
    tier = MembershipTier.create!(name: "Partially Synced", price_cents: 500, currency: "usd", interval: :month, stripe_product_id: "prod_existing_test")

    mock_price = OpenStruct.new(id: "price_only_test")
    PaymentService::Stripe.define_method(:create_price) { |**_args| mock_price }
    PaymentService::Stripe.define_method(:create_product) { |**_args| raise "should not be called" }

    SyncMembershipTierJob.perform_now(tier)

    tier.reload
    assert_equal "prod_existing_test", tier.stripe_product_id
    assert_equal "price_only_test", tier.stripe_price_id
  ensure
    SiteSetting.current.update!(stripe_secret_key: nil, stripe_publishable_key: nil)
    PaymentService::Stripe.remove_method(:create_product) if PaymentService::Stripe.method_defined?(:create_product, false)
    PaymentService::Stripe.remove_method(:create_price) if PaymentService::Stripe.method_defined?(:create_price, false)
  end
end
