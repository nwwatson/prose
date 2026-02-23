require "test_helper"

class UnsubscribesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @subscriber = subscribers(:confirmed)
    @token = Rails.application.message_verifier("unsubscribe").generate(
      @subscriber.id,
      expires_in: 30.days
    )
  end

  test "GET show displays confirmation page with valid token" do
    get unsubscribe_path(token: @token)
    assert_response :success
    assert_select "form"
    assert_match @subscriber.email, response.body
  end

  test "GET show redirects with invalid token" do
    get unsubscribe_path(token: "invalid-token")
    assert_redirected_to root_path
  end

  test "POST create unsubscribes the subscriber" do
    assert_nil @subscriber.unsubscribed_at

    post unsubscribe_path, params: { token: @token }
    assert_response :success

    @subscriber.reload
    assert @subscriber.unsubscribed?
  end

  test "POST create with invalid token redirects" do
    post unsubscribe_path, params: { token: "bad-token" }
    assert_redirected_to root_path
  end

  test "POST create is idempotent" do
    @subscriber.unsubscribe!
    original_time = @subscriber.unsubscribed_at

    post unsubscribe_path, params: { token: @token }
    assert_response :success

    assert_equal original_time.to_i, @subscriber.reload.unsubscribed_at.to_i
  end
end
