require "test_helper"

class Admin::RevenueControllerTest < ActionDispatch::IntegrationTest
  setup do
    SiteSetting.current.update!(stripe_secret_key: "sk_test", stripe_publishable_key: "pk_test")
  end

  teardown do
    SiteSetting.current.update!(stripe_secret_key: nil, stripe_publishable_key: nil)
  end

  test "GET show requires authentication" do
    get admin_revenue_path
    assert_redirected_to new_admin_session_path
  end

  test "GET show renders for admin" do
    sign_in_as(:admin)
    get admin_revenue_path
    assert_response :success
  end

  test "GET show with range parameter" do
    sign_in_as(:admin)
    get admin_revenue_path(range: "7d")
    assert_response :success
  end

  test "GET show redirects with an alert when payments are not configured" do
    sign_in_as(:admin)
    SiteSetting.current.update!(stripe_secret_key: nil, stripe_publishable_key: nil)

    get admin_revenue_path

    assert_redirected_to admin_root_path
    assert_equal I18n.t("flash.payments.not_configured"), flash[:alert]
  end
end
