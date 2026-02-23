require "test_helper"

class Admin::NewsletterSettingsControllerTest < ActionDispatch::IntegrationTest
  test "GET edit requires authentication" do
    get edit_admin_newsletter_settings_path
    assert_redirected_to new_admin_session_path
  end

  test "GET edit renders for admin" do
    sign_in_as(:admin)
    get edit_admin_newsletter_settings_path
    assert_response :success
    assert_select "h1", text: "Newsletter Settings"
  end

  test "PATCH update saves email branding params" do
    sign_in_as(:admin)
    patch admin_newsletter_settings_path, params: {
      site_setting: {
        email_accent_color: "#ff0000",
        email_background_color: "#f5f5f5",
        email_body_text_color: "#333333",
        email_heading_color: "#111111",
        email_footer_text: "123 Main St",
        email_preheader_text: "Latest news"
      }
    }
    assert_redirected_to edit_admin_newsletter_settings_path

    setting = SiteSetting.current
    assert_equal "#ff0000", setting.email_accent_color
    assert_equal "#f5f5f5", setting.email_background_color
    assert_equal "#333333", setting.email_body_text_color
    assert_equal "#111111", setting.email_heading_color
    assert_equal "123 Main St", setting.email_footer_text
    assert_equal "Latest news", setting.email_preheader_text
  end

  test "PATCH update saves email service params" do
    sign_in_as(:admin)
    patch admin_newsletter_settings_path, params: {
      site_setting: {
        email_provider: "sendgrid",
        sendgrid_api_key: "SG.test_key_123"
      }
    }
    assert_redirected_to edit_admin_newsletter_settings_path

    setting = SiteSetting.current
    assert_equal "sendgrid", setting.email_provider
    assert_equal "SG.test_key_123", setting.sendgrid_api_key
  end

  test "PATCH update does not overwrite sendgrid_api_key with mask" do
    sign_in_as(:admin)
    SiteSetting.current.update!(sendgrid_api_key: "SG.real_key")

    patch admin_newsletter_settings_path, params: {
      site_setting: { sendgrid_api_key: "\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022" }
    }
    assert_redirected_to edit_admin_newsletter_settings_path
    assert_equal "SG.real_key", SiteSetting.current.sendgrid_api_key
  end

  test "PATCH update clears sendgrid_api_key when blank" do
    sign_in_as(:admin)
    SiteSetting.current.update!(sendgrid_api_key: "SG.real_key")

    patch admin_newsletter_settings_path, params: {
      site_setting: { sendgrid_api_key: "" }
    }
    assert_redirected_to edit_admin_newsletter_settings_path
    assert_equal "", SiteSetting.current.sendgrid_api_key
  end
end
