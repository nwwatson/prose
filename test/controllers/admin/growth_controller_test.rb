require "test_helper"

class Admin::GrowthControllerTest < ActionDispatch::IntegrationTest
  test "GET show requires authentication" do
    get admin_growth_path
    assert_redirected_to new_admin_session_path
  end

  test "GET show renders for signed in user" do
    sign_in_as(:admin)
    get admin_growth_path
    assert_response :success
    assert_select "h1", text: "Subscriber Growth"
  end

  test "GET show with 6mo range" do
    sign_in_as(:admin)
    get admin_growth_path(range: "6mo")
    assert_response :success
  end

  test "GET show with 12mo range" do
    sign_in_as(:admin)
    get admin_growth_path(range: "12mo")
    assert_response :success
  end

  test "GET show with 24mo range" do
    sign_in_as(:admin)
    get admin_growth_path(range: "24mo")
    assert_response :success
  end

  test "GET show with all range" do
    sign_in_as(:admin)
    get admin_growth_path(range: "all")
    assert_response :success
  end
end
