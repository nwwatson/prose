require "test_helper"

class SiteSettingTest < ActiveSupport::TestCase
  test "current returns existing setting" do
    setting = SiteSetting.create!(site_name: "My Blog")
    assert_equal setting, SiteSetting.current
  end

  test "current creates default if none exist" do
    SiteSetting.delete_all
    setting = SiteSetting.current
    assert_equal "Prose", setting.site_name
    assert_equal "A thoughtfully crafted publication", setting.site_description
  end

  test "validates site_name presence" do
    setting = SiteSetting.new(site_name: "")
    assert_not setting.valid?
    assert_includes setting.errors[:site_name], "can't be blank"
  end

  test "background_color defaults to cream" do
    SiteSetting.delete_all
    setting = SiteSetting.current
    assert_equal "cream", setting.background_color
  end

  test "validates background_color inclusion" do
    setting = SiteSetting.current
    setting.background_color = "neon_pink"
    assert_not setting.valid?
    assert_includes setting.errors[:background_color], "is not included in the list"
  end

  test "accepts valid background_color" do
    setting = SiteSetting.current
    setting.background_color = "sage"
    assert setting.valid?
  end

  test "background_hex returns hex for selected color" do
    setting = SiteSetting.current
    setting.background_color = "cool_gray"
    assert_equal "#f0f2f4", setting.background_hex
  end

  test "background_hex returns cream hex by default" do
    setting = SiteSetting.current
    assert_equal "#faf7f2", setting.background_hex
  end

  # Localization concern tests
  test "locale defaults to en" do
    SiteSetting.delete_all
    setting = SiteSetting.current
    assert_equal "en", setting.locale
  end

  test "validates locale inclusion in supported locales" do
    setting = SiteSetting.current
    setting.locale = "fr"
    assert_not setting.valid?
    assert_includes setting.errors[:locale], "is not included in the list"
  end

  test "accepts valid locale" do
    setting = SiteSetting.current
    setting.locale = "es"
    assert setting.valid?
  end

  test "locale_name returns human-readable name for locale" do
    setting = SiteSetting.current
    setting.locale = "es"
    assert_equal "Español", setting.locale_name
  end

  test "locale_name returns English for default locale" do
    setting = SiteSetting.current
    assert_equal "English", setting.locale_name
  end

  test "locale_name falls back to English for unknown locale" do
    setting = SiteSetting.current
    # Bypass validation to test the fallback
    setting.instance_variable_set(:@attributes, setting.instance_variable_get(:@attributes))
    setting.send(:write_attribute, :locale, "xx")
    assert_equal "English", setting.locale_name
  end

  test "SUPPORTED_LOCALES is frozen" do
    assert SiteSetting::Localization::SUPPORTED_LOCALES.frozen?
  end

  test "SUPPORTED_LOCALES contains en and es" do
    locales = SiteSetting::Localization::SUPPORTED_LOCALES
    assert_equal({ "en" => "English", "es" => "Español" }, locales)
  end
end
