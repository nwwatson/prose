require "test_helper"

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
