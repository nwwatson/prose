require "test_helper"

class User::AuthenticatableTest < ActiveSupport::TestCase
  test "authenticate_by_email_and_password with valid credentials" do
    user = User.authenticate_by_email_and_password("admin@example.com", "P@ssw0rd!Strong1")
    assert_equal users(:admin), user
  end

  test "authenticate_by_email_and_password with wrong password" do
    result = User.authenticate_by_email_and_password("admin@example.com", "wrongpassword")
    assert_equal false, result
  end

  test "authenticate_by_email_and_password with unknown email" do
    result = User.authenticate_by_email_and_password("unknown@example.com", "P@ssw0rd!Strong1")
    assert_nil result
  end

  test "authenticate_by_email_and_password normalizes email" do
    user = User.authenticate_by_email_and_password("  ADMIN@Example.COM  ", "P@ssw0rd!Strong1")
    assert_equal users(:admin), user
  end

  test "create_session! creates a session for the user" do
    user = users(:admin)
    assert_difference "Session.count", 1 do
      session = user.create_session!(ip_address: "1.2.3.4", user_agent: "TestBrowser")
      assert_equal user, session.user
      assert_equal "1.2.3.4", session.ip_address
      assert_equal "TestBrowser", session.user_agent
      assert session.token.present?
      assert session.expires_at > Time.current
    end
  end
end
