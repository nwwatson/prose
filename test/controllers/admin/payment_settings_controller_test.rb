require "test_helper"

class Admin::PaymentSettingsControllerTest < ActionDispatch::IntegrationTest
  test "GET edit requires authentication" do
    get edit_admin_payment_settings_path
    assert_redirected_to new_admin_session_path
  end

  test "GET edit renders for admin" do
    sign_in_as(:admin)
    get edit_admin_payment_settings_path
    assert_response :success
  end

  test "PATCH update saves currency" do
    sign_in_as(:admin)
    patch admin_payment_settings_path, params: { site_setting: { payments_currency: "eur" } }
    assert_redirected_to edit_admin_payment_settings_path

    assert_equal "eur", SiteSetting.current.payments_currency
  ensure
    SiteSetting.current.update!(payments_currency: "usd")
  end

  test "PATCH update does not overwrite masked keys" do
    sign_in_as(:admin)
    SiteSetting.current.update!(stripe_secret_key: "sk_test_original")

    patch admin_payment_settings_path, params: {
      site_setting: { stripe_secret_key: "\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022" }
    }
    assert_redirected_to edit_admin_payment_settings_path
    assert_equal "sk_test_original", SiteSetting.current.stripe_secret_key
  ensure
    SiteSetting.current.update!(stripe_secret_key: nil)
  end
end
