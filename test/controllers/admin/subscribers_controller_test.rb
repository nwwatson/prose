require "test_helper"

class Admin::SubscribersControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(:admin)
  end

  test "GET index lists subscribers" do
    get admin_subscribers_path
    assert_response :success
    assert_select "table"
  end

  test "GET show renders subscriber" do
    get admin_subscriber_path(subscribers(:confirmed))
    assert_response :success
  end

  test "requires authentication" do
    delete admin_session_path
    get admin_subscribers_path
    assert_redirected_to new_admin_session_path
  end
end
