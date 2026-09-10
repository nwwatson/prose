require "test_helper"

class Admin::WebhookDeliveriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(:admin)
  end

  test "GET index lists deliveries for the webhook" do
    get admin_webhook_webhook_deliveries_path(webhooks(:post_events_webhook))
    assert_response :success
  end

  test "requires authentication" do
    delete admin_session_path
    get admin_webhook_webhook_deliveries_path(webhooks(:post_events_webhook))
    assert_redirected_to new_admin_session_path
  end
end
