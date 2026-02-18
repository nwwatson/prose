require "test_helper"

class Admin::SessionsControllerTest < ActionDispatch::IntegrationTest
  test "GET new renders login form" do
    get new_admin_session_path
    assert_response :success
    assert_select "input[name='email']"
    assert_select "input[name='password']"
  end

  test "POST create with valid credentials signs in and redirects" do
    post admin_session_path, params: { email: "admin@example.com", password: "P@ssw0rd!Strong1" }
    assert_redirected_to admin_root_path
    follow_redirect!
    assert_response :success
  end

  test "POST create with invalid credentials re-renders login" do
    post admin_session_path, params: { email: "admin@example.com", password: "wrong" }
    assert_response :unprocessable_entity
    assert_select "p", text: /Invalid email or password/
  end

  test "POST create with unknown email re-renders login" do
    post admin_session_path, params: { email: "unknown@example.com", password: "P@ssw0rd!Strong1" }
    assert_response :unprocessable_entity
  end

  test "DELETE destroy signs out and redirects to login" do
    sign_in_as(:admin)
    delete admin_session_path
    assert_redirected_to new_admin_session_path
  end

  test "signed in user visiting login page is redirected to dashboard" do
    sign_in_as(:admin)
    get new_admin_session_path
    assert_redirected_to admin_root_path
  end
end
