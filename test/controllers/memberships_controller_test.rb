require "test_helper"

class MembershipsControllerTest < ActionDispatch::IntegrationTest
  setup do
    SiteSetting.current.update!(stripe_secret_key: "sk_test", stripe_publishable_key: "pk_test")
  end

  teardown do
    SiteSetting.current.update!(stripe_secret_key: nil, stripe_publishable_key: nil)
  end

  test "GET index renders pricing page when payments configured" do
    get memberships_path
    assert_response :success
  end

  test "GET index redirects when payments not configured" do
    SiteSetting.current.update!(stripe_secret_key: nil, stripe_publishable_key: nil)
    get memberships_path
    assert_redirected_to root_path
  end

  test "POST checkout requires signed-in subscriber" do
    post checkout_memberships_path(tier_id: membership_tiers(:monthly).id)
    assert_redirected_to memberships_path
  end

  test "GET success renders confirmation" do
    get success_memberships_path
    assert_response :success
  end

  test "GET portal redirects when no customer" do
    get portal_memberships_path
    assert_redirected_to memberships_path
  end
end
