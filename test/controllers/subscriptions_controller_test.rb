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

  test "POST create with source_post_id captures it for new subscriber" do
    published_post = posts(:published_post)
    post subscriptions_path, params: { email: "withpost@example.com", source_post_id: published_post.id }
    subscriber = Subscriber.find_by(email: "withpost@example.com")
    assert_equal published_post.id, subscriber.source_post_id
  end

  test "POST create without source_post_id leaves it nil" do
    post subscriptions_path, params: { email: "nopost@example.com" }
    subscriber = Subscriber.find_by(email: "nopost@example.com")
    assert_nil subscriber.source_post_id
  end

  test "POST create with existing subscriber does not overwrite source_post_id" do
    subscriber = subscribers(:from_published_post)
    original_source = subscriber.source_post_id
    post subscriptions_path, params: { email: subscriber.email, source_post_id: posts(:featured_post).id }
    assert_equal original_source, subscriber.reload.source_post_id
  end
end
