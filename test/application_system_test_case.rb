require "test_helper"

# Capybara 3.40's ChromeDriver#reset! clears storage between tests with
# `Storage.clearDataForOrigin` and origin "*". Chrome 158 rejects that ("* is not a
# valid URL"), so every system test errors in teardown and localStorage leaks into
# the next test. Clear cookies browser-wide and storage for the app server's origin
# instead. Remove this once Capybara stops sending the wildcard origin.
module ClearStorageWithoutWildcardOrigin
  def execute_cdp(cmd, params = {})
    return super unless cmd == "Storage.clearDataForOrigin" && params[:origin] == "*"

    super("Storage.clearCookies")
    storage_types = params[:storageTypes].to_s.split(",") - [ "cookies" ]
    origin = Capybara.current_session.server&.base_url
    super(cmd, params.merge(origin: origin, storageTypes: storage_types.join(","))) if origin && storage_types.any?
  end
end
Capybara::Selenium::Driver::ChromeDriver.prepend(ClearStorageWithoutWildcardOrigin)

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 900 ]

  def sign_in_admin(user = users(:admin))
    visit new_admin_session_path
    fill_in "email", with: user.email
    fill_in "password", with: "P@ssw0rd!Strong1"
    click_button I18n.t("shared.sign_in")
    assert_current_path admin_root_path
  end

  def with_mobile_viewport(width: 375, height: 812)
    current_window.resize_to(width, height)
    yield
  ensure
    current_window.resize_to(1400, 900)
  end

  def with_tablet_viewport(width: 768, height: 1024)
    current_window.resize_to(width, height)
    yield
  ensure
    current_window.resize_to(1400, 900)
  end
end
