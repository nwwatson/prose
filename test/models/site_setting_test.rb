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
end
