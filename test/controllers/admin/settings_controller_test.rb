require "test_helper"

class Admin::SettingsControllerTest < ActionDispatch::IntegrationTest
  test "GET edit requires authentication" do
    get edit_admin_settings_path
    assert_redirected_to new_admin_session_path
  end

  test "GET edit renders for admin" do
    sign_in_as(:admin)
    get edit_admin_settings_path
    assert_response :success
    assert_select "h1", text: "Site Settings"
  end

  test "PATCH update saves settings" do
    sign_in_as(:admin)
    patch admin_settings_path, params: { site_setting: { site_name: "My Blog", site_description: "A great blog" } }
    assert_redirected_to edit_admin_settings_path

    setting = SiteSetting.current
    assert_equal "My Blog", setting.site_name
    assert_equal "A great blog", setting.site_description
  end

  test "PATCH update rejects blank site_name" do
    sign_in_as(:admin)
    patch admin_settings_path, params: { site_setting: { site_name: "" } }
    assert_response :unprocessable_entity
  end

  test "GET edit renders typography fields" do
    sign_in_as(:admin)
    get edit_admin_settings_path
    assert_response :success
    assert_select "select[name='site_setting[heading_font]']"
    assert_select "select[name='site_setting[subtitle_font]']"
    assert_select "select[name='site_setting[body_font]']"
    assert_select "input[name='site_setting[heading_font_size]']"
  end

  test "PATCH update persists typography settings" do
    sign_in_as(:admin)
    patch admin_settings_path, params: {
      site_setting: {
        heading_font: "Inter",
        subtitle_font: "Lora",
        body_font: "Merriweather",
        heading_font_size: 3.0,
        subtitle_font_size: 1.5,
        body_font_size: 1.25
      }
    }
    assert_redirected_to edit_admin_settings_path

    setting = SiteSetting.current
    assert_equal "Inter", setting.heading_font
    assert_equal "Lora", setting.subtitle_font
    assert_equal "Merriweather", setting.body_font
    assert_equal 3.0, setting.heading_font_size.to_f
  end

  test "PATCH update rejects invalid font name" do
    sign_in_as(:admin)
    patch admin_settings_path, params: { site_setting: { heading_font: "Comic Sans MS" } }
    assert_response :unprocessable_entity
  end

  test "PATCH update persists background_color" do
    sign_in_as(:admin)
    patch admin_settings_path, params: { site_setting: { background_color: "sage" } }
    assert_redirected_to edit_admin_settings_path

    assert_equal "sage", SiteSetting.current.background_color
  end

  test "PATCH update rejects invalid background_color" do
    sign_in_as(:admin)
    patch admin_settings_path, params: { site_setting: { background_color: "neon_pink" } }
    assert_response :unprocessable_entity
  end

  test "GET edit renders background_color select" do
    sign_in_as(:admin)
    get edit_admin_settings_path
    assert_response :success
    assert_select "select[name='site_setting[background_color]']"
  end
end
