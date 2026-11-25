require "test_helper"

class Admin::RevenueControllerTest < ActionDispatch::IntegrationTest
  setup do
    configure_stripe!
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
    unconfigure_stripe!

    get admin_revenue_path

    assert_redirected_to admin_root_path
    assert_equal I18n.t("flash.payments.not_configured"), flash[:alert]
  end
end
