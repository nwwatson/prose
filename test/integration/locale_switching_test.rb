require "test_helper"

class LocaleSwitchingTest < ActionDispatch::IntegrationTest
  test "pages render in English by default" do
    get root_path
    assert_response :success
    assert_equal :en, I18n.locale
  end

  test "pages render in Spanish when locale is set to es" do
    setting = SiteSetting.current
    setting.update!(locale: "es")

    get root_path
    assert_response :success
    assert_equal :es, I18n.locale
  ensure
    setting.update!(locale: "en")
  end

  test "locale resets between requests based on site setting" do
    setting = SiteSetting.current

    setting.update!(locale: "es")
    get root_path
    assert_equal :es, I18n.locale

    setting.update!(locale: "en")
    get root_path
    assert_equal :en, I18n.locale
  end

  test "all app locale keys exist in Spanish translation" do
    # Only check our app-specific top-level keys, not Rails built-in ones
    app_keys = %i[shared layouts posts subscriptions comments tags pages
                  unsubscribes handles tag_select admin subscriber_mailer
                  post_notification_mailer newsletter_mailer flash]

    I18n.backend.send(:init_translations) unless I18n.backend.initialized?
    es_keys = I18n.backend.translations[:es]&.keys || []

    missing = app_keys - es_keys
    assert_empty missing, "Spanish locale is missing app keys: #{missing.join(', ')}"
  end
end
