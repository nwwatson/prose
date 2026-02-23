require "test_helper"

class Admin::NewslettersControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(:admin)
  end

  test "GET index lists newsletters" do
    get admin_newsletters_path
    assert_response :success
    assert_select "table"
  end

  test "GET index filters by status" do
    get admin_newsletters_path(status: "sent")
    assert_response :success
  end

  test "GET index filters by draft status" do
    get admin_newsletters_path(status: "draft")
    assert_response :success
  end

  test "GET new renders form" do
    get new_admin_newsletter_path
    assert_response :success
    assert_select "form"
  end

  test "POST create creates a draft newsletter" do
    assert_difference "Newsletter.count", 1 do
      post admin_newsletters_path, params: { newsletter: { title: "New Campaign" } }
    end
    assert_redirected_to edit_admin_newsletter_path(Newsletter.last)
    assert Newsletter.last.draft?
  end

  test "POST create with invalid data re-renders form" do
    post admin_newsletters_path, params: { newsletter: { title: "" } }
    assert_response :unprocessable_entity
  end

  test "GET edit renders form" do
    get edit_admin_newsletter_path(newsletters(:draft_newsletter))
    assert_response :success
  end

  test "PATCH update updates newsletter" do
    patch admin_newsletter_path(newsletters(:draft_newsletter)), params: { newsletter: { title: "Updated Title" } }
    assert_redirected_to edit_admin_newsletter_path(newsletters(:draft_newsletter))
    assert_equal "Updated Title", newsletters(:draft_newsletter).reload.title
  end

  test "DELETE destroy removes newsletter" do
    assert_difference "Newsletter.count", -1 do
      delete admin_newsletter_path(newsletters(:draft_newsletter))
    end
    assert_redirected_to admin_newsletters_path
  end

  test "POST create as JSON returns created" do
    assert_difference "Newsletter.count", 1 do
      post admin_newsletters_path, params: { newsletter: { title: "JSON Newsletter" } }, as: :json
    end
    assert_response :created
    json = JSON.parse(response.body)
    assert json["id"].present?
    assert json["url"].present?
    assert json["edit_url"].present?
  end

  test "PATCH update as JSON returns ok" do
    patch admin_newsletter_path(newsletters(:draft_newsletter)), params: { newsletter: { title: "Updated via JSON" } }, as: :json
    assert_response :ok
    json = JSON.parse(response.body)
    assert json["url"].present?
    assert_equal "Updated via JSON", newsletters(:draft_newsletter).reload.title
  end

  test "POST send_newsletter sends a draft newsletter" do
    assert_enqueued_with(job: SendNewsletterJob) do
      post send_newsletter_admin_newsletter_path(newsletters(:draft_newsletter))
    end
    assert_redirected_to admin_newsletters_path
    assert newsletters(:draft_newsletter).reload.sending?
  end

  test "POST send_newsletter rejects already sent newsletter" do
    post send_newsletter_admin_newsletter_path(newsletters(:sent_newsletter))
    assert_redirected_to edit_admin_newsletter_path(newsletters(:sent_newsletter))
    assert_equal "This newsletter cannot be sent.", flash[:alert]
  end

  test "POST schedule schedules a newsletter" do
    post schedule_admin_newsletter_path(newsletters(:draft_newsletter)), params: { scheduled_for: 1.day.from_now.iso8601 }
    assert_redirected_to admin_newsletters_path
    assert newsletters(:draft_newsletter).reload.scheduled?
  end

  test "GET preview renders with newsletter_mailer layout" do
    get preview_admin_newsletter_path(newsletters(:draft_newsletter))
    assert_response :success
    assert_match "Unsubscribe", response.body
  end

  test "POST create with template params" do
    post admin_newsletters_path, params: {
      newsletter: { title: "Styled Campaign", template: "branded", accent_color: "#ff0000", preheader_text: "Preview!" }
    }
    newsletter = Newsletter.last
    assert_equal "branded", newsletter.template
    assert_equal "#ff0000", newsletter.accent_color
    assert_equal "Preview!", newsletter.preheader_text
  end

  test "PATCH update with template params" do
    newsletter = newsletters(:draft_newsletter)
    patch admin_newsletter_path(newsletter), params: {
      newsletter: { template: "editorial", accent_color: "#00ff00" }
    }
    newsletter.reload
    assert_equal "editorial", newsletter.template
    assert_equal "#00ff00", newsletter.accent_color
  end

  test "GET show displays newsletter stats" do
    get admin_newsletter_path(newsletters(:sent_newsletter))
    assert_response :success
    assert_select "h1", newsletters(:sent_newsletter).title
  end

  test "GET show works for draft newsletter" do
    get admin_newsletter_path(newsletters(:draft_newsletter))
    assert_response :success
  end

  test "requires authentication" do
    delete admin_session_path
    get admin_newsletters_path
    assert_redirected_to new_admin_session_path
  end
end
