require "test_helper"

class Admin::MembershipsControllerTest < ActionDispatch::IntegrationTest
  test "GET index requires authentication" do
    get admin_memberships_path
    assert_redirected_to new_admin_session_path
  end

  test "GET index renders for admin" do
    sign_in_as(:admin)
    get admin_memberships_path
    assert_response :success
  end

  test "GET index filters by status" do
    sign_in_as(:admin)
    get admin_memberships_path(status: "active")
    assert_response :success
  end

  test "GET show renders membership details" do
    sign_in_as(:admin)
    get admin_membership_path(memberships(:active_membership))
    assert_response :success
  end

  test "DELETE destroy cancels complimentary membership" do
    sign_in_as(:admin)

    # Create a complimentary membership (no Stripe subscription) so cancel! won't call Stripe
    membership = Membership.create!(
      subscriber: subscribers(:with_token),
      membership_tier: membership_tiers(:monthly),
      status: :active,
      current_period_start: Time.current,
      current_period_end: 100.years.from_now
    )

    delete admin_membership_path(membership)
    assert_redirected_to admin_memberships_path
    assert membership.reload.canceled?
  end
end
