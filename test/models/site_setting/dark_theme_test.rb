require "test_helper"

class SiteSetting::DarkThemeTest < ActiveSupport::TestCase
  setup do
    @setting = SiteSetting.current
  end

  test "default dark theme is midnight" do
    assert_equal "midnight", @setting.dark_theme
  end

  test "predefined theme returns correct hex values" do
    @setting.dark_theme = "charcoal"
    assert_equal "#1e1e1e", @setting.dark_bg_hex
    assert_equal "#d4d4d4", @setting.dark_text_hex
    assert_equal "#6cb6ff", @setting.dark_accent_hex
  end

  test "midnight theme returns correct hex values" do
    @setting.dark_theme = "midnight"
    assert_equal "#1a1a2e", @setting.dark_bg_hex
    assert_equal "#e0def4", @setting.dark_text_hex
    assert_equal "#7ba4cc", @setting.dark_accent_hex
  end

  test "ocean theme returns correct hex values" do
    @setting.dark_theme = "ocean"
    assert_equal "#0d1b2a", @setting.dark_bg_hex
    assert_equal "#e0e1dd", @setting.dark_text_hex
    assert_equal "#90bce0", @setting.dark_accent_hex
  end

  test "forest theme returns correct hex values" do
    @setting.dark_theme = "forest"
    assert_equal "#1a2e1a", @setting.dark_bg_hex
    assert_equal "#d4e0d4", @setting.dark_text_hex
    assert_equal "#8fbc8f", @setting.dark_accent_hex
  end

  test "custom theme returns user-provided hex values" do
    @setting.dark_theme = "custom"
    @setting.dark_bg_color = "#111111"
    @setting.dark_text_color = "#eeeeee"
    @setting.dark_accent_color = "#ff6600"

    assert_equal "#111111", @setting.dark_bg_hex
    assert_equal "#eeeeee", @setting.dark_text_hex
    assert_equal "#ff6600", @setting.dark_accent_hex
  end

  test "validates hex format for custom colors" do
    @setting.dark_theme = "custom"
    @setting.dark_bg_color = "not-a-hex"
    @setting.dark_text_color = "#eeeeee"
    @setting.dark_accent_color = "#ff6600"

    assert_not @setting.valid?
    assert @setting.errors[:dark_bg_color].any?
  end

  test "does not validate hex format for predefined themes" do
    @setting.dark_theme = "midnight"
    @setting.dark_bg_color = "whatever"
    assert @setting.valid?
  end

  test "validates dark_theme inclusion" do
    @setting.dark_theme = "nonexistent"
    assert_not @setting.valid?
    assert @setting.errors[:dark_theme].any?
  end
end
