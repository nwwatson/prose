require "test_helper"

class Admin::MembershipTiersControllerTest < ActionDispatch::IntegrationTest
  test "GET index requires authentication" do
    get admin_membership_tiers_path
    assert_redirected_to new_admin_session_path
  end

  test "GET index renders for admin" do
    sign_in_as(:admin)
    get admin_membership_tiers_path
    assert_response :success
  end

  test "GET index runs a single grouped count query regardless of tier count" do
    sign_in_as(:admin)
    5.times { |i| MembershipTier.create!(name: "Extra #{i}", price_cents: 500, currency: "usd", interval: :month) }

    membership_queries = 0
    callback = lambda do |*, payload|
      membership_queries += 1 if payload[:sql].match?(/FROM "memberships"/)
    end

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      get admin_membership_tiers_path
    end

    assert_response :success
    assert_equal 1, membership_queries
  end

  test "GET new renders form" do
    sign_in_as(:admin)
    get new_admin_membership_tier_path
    assert_response :success
  end

  test "POST create creates tier" do
    sign_in_as(:admin)
    assert_difference "MembershipTier.count", 1 do
      post admin_membership_tiers_path, params: {
        membership_tier: { name: "Premium", price_cents: 2000, currency: "usd", interval: "month" }
      }
    end
    assert_redirected_to admin_membership_tiers_path
  end

  test "POST create rejects invalid tier" do
    sign_in_as(:admin)
    assert_no_difference "MembershipTier.count" do
      post admin_membership_tiers_path, params: {
        membership_tier: { name: "", price_cents: 0 }
      }
    end
    assert_response :unprocessable_entity
  end

  test "GET edit renders form" do
    sign_in_as(:admin)
    get edit_admin_membership_tier_path(membership_tiers(:monthly))
    assert_response :success
  end

  test "PATCH update updates tier" do
    sign_in_as(:admin)
    tier = membership_tiers(:monthly)
    patch admin_membership_tier_path(tier), params: {
      membership_tier: { name: "Updated Monthly" }
    }
    assert_redirected_to admin_membership_tiers_path
    assert_equal "Updated Monthly", tier.reload.name
  end

  test "DELETE destroy deletes tier without members" do
    sign_in_as(:admin)
    tier = membership_tiers(:inactive)
    assert_difference "MembershipTier.count", -1 do
      delete admin_membership_tier_path(tier)
    end
    assert_redirected_to admin_membership_tiers_path
  end
end
