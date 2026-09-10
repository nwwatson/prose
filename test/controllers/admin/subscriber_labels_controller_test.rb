require "test_helper"

class Admin::SubscriberLabelsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(:admin)
  end

  test "GET index lists labels" do
    get admin_subscriber_labels_path
    assert_response :success
  end

  test "GET index runs a single grouped count query regardless of label count" do
    5.times { |i| SubscriberLabel.create!(name: "Extra #{i}", color: "#123456") }

    labeling_queries = 0
    callback = lambda do |*, payload|
      labeling_queries += 1 if payload[:sql].match?(/FROM "subscriber_labelings"/)
    end

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      get admin_subscriber_labels_path
    end

    assert_response :success
    assert_equal 1, labeling_queries
  end

  test "GET new renders form" do
    get new_admin_subscriber_label_path
    assert_response :success
  end

  test "POST create creates label" do
    assert_difference "SubscriberLabel.count", 1 do
      post admin_subscriber_labels_path, params: { subscriber_label: { name: "Premium", color: "#FFD700" } }
    end
    assert_redirected_to admin_subscriber_labels_path
  end

  test "POST create with invalid data renders form" do
    assert_no_difference "SubscriberLabel.count" do
      post admin_subscriber_labels_path, params: { subscriber_label: { name: "", color: "#FFD700" } }
    end
    assert_response :unprocessable_entity
  end

  test "GET edit renders form" do
    get edit_admin_subscriber_label_path(subscriber_labels(:vip))
    assert_response :success
  end

  test "PATCH update updates label" do
    label = subscriber_labels(:vip)
    patch admin_subscriber_label_path(label), params: { subscriber_label: { name: "Super VIP" } }
    assert_redirected_to admin_subscriber_labels_path
    assert_equal "Super VIP", label.reload.name
  end

  test "DELETE destroy removes label" do
    assert_difference "SubscriberLabel.count", -1 do
      delete admin_subscriber_label_path(subscriber_labels(:inactive))
    end
    assert_redirected_to admin_subscriber_labels_path
  end

  test "requires authentication" do
    delete admin_session_path
    get admin_subscriber_labels_path
    assert_redirected_to new_admin_session_path
  end
end
