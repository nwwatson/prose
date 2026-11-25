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
    configure_stripe!
    tier = MembershipTier.create!(name: "Unsynced", price_cents: 500, currency: "usd", interval: :month)

    mock_product = OpenStruct.new(id: "prod_new_test")
    mock_price = OpenStruct.new(id: "price_new_test")
    with_instance_stub(PaymentService::Stripe, :create_product, ->(**) { mock_product }) do
      with_instance_stub(PaymentService::Stripe, :create_price, ->(**) { mock_price }) do
        SyncMembershipTierJob.perform_now(tier)
      end
    end

    tier.reload
    assert_equal "prod_new_test", tier.stripe_product_id
    assert_equal "price_new_test", tier.stripe_price_id
  end

  test "only creates the price when the product already exists" do
    configure_stripe!
    tier = MembershipTier.create!(name: "Partially Synced", price_cents: 500, currency: "usd", interval: :month, stripe_product_id: "prod_existing_test")

    mock_price = OpenStruct.new(id: "price_only_test")
    with_instance_stub(PaymentService::Stripe, :create_price, ->(**) { mock_price }) do
      with_instance_stub(PaymentService::Stripe, :create_product, ->(**) { raise "should not be called" }) do
        SyncMembershipTierJob.perform_now(tier)
      end
    end

    tier.reload
    assert_equal "prod_existing_test", tier.stripe_product_id
    assert_equal "price_only_test", tier.stripe_price_id
  end
end
