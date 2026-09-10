require "test_helper"

class Admin::WebhooksControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    sign_in_as(:admin)
  end

  test "GET index lists webhooks" do
    get admin_webhooks_path
    assert_response :success
  end

  test "GET new renders form" do
    get new_admin_webhook_path
    assert_response :success
  end

  test "POST create creates webhook and flashes the raw secret" do
    assert_difference "Webhook.count", 1 do
      post admin_webhooks_path, params: { webhook: { url: "https://example.com/hook", events: [ "post.published" ] } }
    end

    webhook = Webhook.order(:created_at).last
    assert_redirected_to edit_admin_webhook_path(webhook)
    assert_equal webhook.signing_secret, flash[:raw_secret]
  end

  test "POST create with invalid data renders form" do
    assert_no_difference "Webhook.count" do
      post admin_webhooks_path, params: { webhook: { url: "", events: [] } }
    end
    assert_response :unprocessable_entity
  end

  test "GET edit renders form" do
    get edit_admin_webhook_path(webhooks(:post_events_webhook))
    assert_response :success
  end

  test "PATCH update updates webhook" do
    webhook = webhooks(:post_events_webhook)
    patch admin_webhook_path(webhook), params: { webhook: { url: webhook.url, events: [ "post.deleted" ] } }
    assert_redirected_to admin_webhooks_path
    assert_equal [ "post.deleted" ], webhook.reload.events
  end

  test "DELETE destroy removes webhook" do
    assert_difference "Webhook.count", -1 do
      delete admin_webhook_path(webhooks(:disabled_webhook))
    end
    assert_redirected_to admin_webhooks_path
  end

  test "POST test enqueues a ping delivery" do
    webhook = webhooks(:post_events_webhook)

    assert_enqueued_with(job: DeliverWebhookJob, args: [ webhook.id, "ping", { message: "This is a test delivery from Prose." } ]) do
      post test_admin_webhook_path(webhook)
    end

    assert_redirected_to admin_webhook_webhook_deliveries_path(webhook)
  end

  test "POST regenerate_secret rotates the signing secret" do
    webhook = webhooks(:post_events_webhook)
    original_secret = webhook.signing_secret

    post regenerate_secret_admin_webhook_path(webhook)

    assert_redirected_to edit_admin_webhook_path(webhook)
    assert_not_equal original_secret, webhook.reload.signing_secret
  end

  test "requires authentication" do
    delete admin_session_path
    get admin_webhooks_path
    assert_redirected_to new_admin_session_path
  end
end
