require "test_helper"

class SubscriptionsControllerTest < ActionDispatch::IntegrationTest
  test "POST create with new email creates subscriber" do
    assert_difference "Subscriber.count", 1 do
      post subscriptions_path, params: { email: "newsubscriber@example.com" }
    end
    assert_redirected_to root_path
  end

  test "POST create with existing email does not create duplicate" do
    assert_no_difference "Subscriber.count" do
      post subscriptions_path, params: { email: "subscriber@example.com" }
    end
    assert_redirected_to root_path
  end

  test "POST create enqueues mailer" do
    assert_enqueued_emails 1 do
      post subscriptions_path, params: { email: "newmail@example.com" }
    end
  end

  test "POST create with turbo stream returns turbo stream" do
    post subscriptions_path, params: { email: "turbo@example.com" }, as: :turbo_stream
    assert_response :success
    assert_includes response.content_type, "turbo-stream"
  end
end
