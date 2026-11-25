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

  test "POST comp grants a complimentary membership to the subscriber" do
    sign_in_as(:admin)
    subscriber = subscribers(:unconfirmed)
    tier = membership_tiers(:monthly)

    assert_difference "Membership.count", 1 do
      post admin_subscriber_comp_membership_path(subscriber), params: { tier_id: tier.id }
    end

    membership = subscriber.memberships.order(:created_at).last
    assert membership.active?
    assert membership.complimentary?
    assert_equal tier, membership.membership_tier
    assert_redirected_to admin_memberships_path
  end

  test "POST comp requires authentication" do
    subscriber = subscribers(:unconfirmed)
    tier = membership_tiers(:monthly)

    post admin_subscriber_comp_membership_path(subscriber), params: { tier_id: tier.id }
    assert_redirected_to new_admin_session_path
  end

  test "GET index ignores an unknown status" do
    sign_in_as(:admin)
    get admin_memberships_path
    all_rows = css_select("tbody tr").size
    assert_operator all_rows, :>, 0

    get admin_memberships_path(status: "bogus")

    assert_response :success
    assert_select "tbody tr", count: all_rows
  end
end
