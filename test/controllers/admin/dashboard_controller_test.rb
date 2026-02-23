require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  test "GET show requires authentication" do
    get admin_root_path
    assert_redirected_to new_admin_session_path
  end

  test "GET show renders for signed in user" do
    sign_in_as(:admin)
    get admin_root_path
    assert_response :success
    assert_select "h1", text: "Dashboard"
  end

  test "GET show renders for writer" do
    sign_in_as(:writer)
    get admin_root_path
    assert_response :success
  end

  test "GET show displays newsletter stats" do
    sign_in_as(:admin)
    get admin_root_path
    assert_response :success
    assert_select "div", text: /Newsletters Sent/
  end
end
