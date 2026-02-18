require "test_helper"

class SessionTest < ActiveSupport::TestCase
  test "generates token on create" do
    session = users(:admin).sessions.create!
    assert session.token.present?
    assert_equal 43, session.token.length # base64 encoded 32 bytes
  end

  test "sets expiry to 14 days by default" do
    session = users(:admin).sessions.create!
    assert_in_delta 14.days.from_now, session.expires_at, 5.seconds
  end

  test "expired? returns true for past expiry" do
    assert sessions(:expired_session).expired?
  end

  test "expired? returns false for future expiry" do
    assert_not sessions(:admin_session).expired?
  end

  test "active scope excludes expired sessions" do
    active = Session.active
    assert_includes active, sessions(:admin_session)
    assert_not_includes active, sessions(:expired_session)
  end

  test "token is unique" do
    tokens = 10.times.map { users(:admin).sessions.create!.token }
    assert_equal tokens.uniq.length, tokens.length
  end
end
