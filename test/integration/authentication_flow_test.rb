require "test_helper"

class AuthenticationFlowTest < ActionDispatch::IntegrationTest
  test "full login and logout flow" do
    # Visit dashboard, get redirected to login
    get admin_root_path
    assert_redirected_to new_admin_session_path

    # Sign in
    post admin_session_path, params: { email: "admin@example.com", password: "P@ssw0rd!Strong1" }
    assert_redirected_to admin_root_path

    # Access dashboard
    follow_redirect!
    assert_response :success
    assert_select "h1", text: "Dashboard"

    # Sign out
    delete admin_session_path
    assert_redirected_to new_admin_session_path

    # Dashboard is no longer accessible
    get admin_root_path
    assert_redirected_to new_admin_session_path
  end

  test "session creates database record" do
    assert_difference "Session.count", 1 do
      post admin_session_path, params: { email: "admin@example.com", password: "P@ssw0rd!Strong1" }
    end
  end

  test "logout destroys session record" do
    sign_in_as(:admin)
    assert_difference "Session.count", -1 do
      delete admin_session_path
    end
  end

  test "expired session requires re-authentication" do
    # Sign in
    post admin_session_path, params: { email: "admin@example.com", password: "P@ssw0rd!Strong1" }
    assert_redirected_to admin_root_path

    # Expire the session
    Session.last.update!(expires_at: 1.minute.ago)

    # Try to access dashboard
    get admin_root_path
    assert_redirected_to new_admin_session_path
  end
end
