require "test_helper"

class Subscriber::AuthenticatableTest < ActiveSupport::TestCase
  test "generate_auth_token! sets token and timestamp" do
    subscriber = subscribers(:confirmed)
    token = subscriber.generate_auth_token!
    assert token.present?
    assert subscriber.auth_token_sent_at.present?
  end

  test "consume_auth_token! with valid token returns true and clears token" do
    subscriber = subscribers(:with_token)
    result = subscriber.consume_auth_token!("valid_test_token_123")
    assert result
    assert_nil subscriber.reload.auth_token
    assert_nil subscriber.auth_token_sent_at
  end

  test "consume_auth_token! with wrong token returns false" do
    subscriber = subscribers(:with_token)
    result = subscriber.consume_auth_token!("wrong_token")
    assert_not result
  end

  test "consume_auth_token! with expired token returns false" do
    subscriber = subscribers(:expired_token)
    result = subscriber.consume_auth_token!("expired_token_456")
    assert_not result
  end

  test "auth_token_expired? returns true when token is old" do
    assert subscribers(:expired_token).auth_token_expired?
  end

  test "auth_token_expired? returns false when token is fresh" do
    assert_not subscribers(:with_token).auth_token_expired?
  end
end
