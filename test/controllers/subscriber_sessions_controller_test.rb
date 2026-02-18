require "test_helper"

class SubscriberSessionsControllerTest < ActionDispatch::IntegrationTest
  test "GET show with valid token signs in subscriber" do
    get subscriber_session_path(token: "valid_test_token_123")
    assert_redirected_to root_path
    assert_equal "You're now signed in.", flash[:notice]
  end

  test "GET show with expired token shows error" do
    get subscriber_session_path(token: "expired_token_456")
    assert_redirected_to root_path
    assert flash[:alert].present?
  end

  test "GET show with invalid token shows error" do
    get subscriber_session_path(token: "nonexistent_token")
    assert_redirected_to root_path
    assert flash[:alert].present?
  end

  test "DELETE destroy clears subscriber session" do
    delete subscriber_session_path
    assert_redirected_to root_path
  end
end
