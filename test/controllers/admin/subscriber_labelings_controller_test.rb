require "test_helper"

class Admin::SubscriberLabelingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(:admin)
  end

  test "POST create assigns label to subscriber" do
    subscriber = subscribers(:unconfirmed)
    label = subscriber_labels(:vip)

    assert_difference "SubscriberLabeling.count", 1 do
      post admin_subscriber_subscriber_labelings_path(subscriber), params: { subscriber_label_id: label.id }
    end
    assert_redirected_to admin_subscriber_path(subscriber)
  end

  test "POST create with turbo stream" do
    subscriber = subscribers(:unconfirmed)
    label = subscriber_labels(:vip)

    post admin_subscriber_subscriber_labelings_path(subscriber),
      params: { subscriber_label_id: label.id },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
  end

  test "DELETE destroy removes label from subscriber" do
    labeling = subscriber_labelings(:confirmed_vip)
    subscriber = labeling.subscriber

    assert_difference "SubscriberLabeling.count", -1 do
      delete admin_subscriber_subscriber_labeling_path(subscriber, labeling)
    end
    assert_redirected_to admin_subscriber_path(subscriber)
  end

  test "DELETE destroy with turbo stream" do
    labeling = subscriber_labelings(:from_published_post_inactive)
    subscriber = labeling.subscriber

    delete admin_subscriber_subscriber_labeling_path(subscriber, labeling),
      headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
  end

  test "requires authentication" do
    delete admin_session_path
    post admin_subscriber_subscriber_labelings_path(subscribers(:confirmed)), params: { subscriber_label_id: subscriber_labels(:vip).id }
    assert_redirected_to new_admin_session_path
  end
end
