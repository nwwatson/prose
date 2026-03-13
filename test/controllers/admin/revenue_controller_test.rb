require "test_helper"

class Admin::RevenueControllerTest < ActionDispatch::IntegrationTest
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
end
