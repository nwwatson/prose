require "test_helper"

class Admin::TrafficControllerTest < ActionDispatch::IntegrationTest
  test "GET show requires authentication" do
    get admin_traffic_path
    assert_redirected_to new_admin_session_path
  end

  test "GET show renders for signed in user" do
    sign_in_as(:admin)
    get admin_traffic_path
    assert_response :success
    assert_select "h1", text: "Traffic Analytics"
  end

  test "GET show accepts range param" do
    sign_in_as(:admin)
    get admin_traffic_path(range: "7d")
    assert_response :success
  end

  test "GET show accepts 90d range" do
    sign_in_as(:admin)
    get admin_traffic_path(range: "90d")
    assert_response :success
  end

  test "GET show accepts all range" do
    sign_in_as(:admin)
    get admin_traffic_path(range: "all")
    assert_response :success
  end

  test "GET show renders for writer" do
    sign_in_as(:writer)
    get admin_traffic_path
    assert_response :success
  end
end
