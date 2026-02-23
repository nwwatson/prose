require "test_helper"

class SiteSetting::EmailBrandingTest < ActiveSupport::TestCase
  setup do
    @setting = SiteSetting.current
  end

  test "valid hex color formats accepted" do
    @setting.email_accent_color = "#ff0000"
    assert @setting.valid?

    @setting.email_accent_color = "#AABBCC"
    assert @setting.valid?
  end

  test "invalid hex color formats rejected" do
    @setting.email_accent_color = "red"
    assert_not @setting.valid?
    assert @setting.errors[:email_accent_color].any?

    @setting.email_accent_color = "#fff"
    assert_not @setting.valid?

    @setting.email_accent_color = "123456"
    assert_not @setting.valid?
  end

  test "blank hex color allowed" do
    @setting.email_accent_color = ""
    assert @setting.valid?
  end

  test "valid template names accepted" do
    %w[minimal branded editorial].each do |template|
      @setting.email_default_template = template
      assert @setting.valid?, "#{template} should be valid"
    end
  end

  test "invalid template name rejected" do
    @setting.email_default_template = "fancy"
    assert_not @setting.valid?
    assert @setting.errors[:email_default_template].any?
  end

  test "valid font families accepted" do
    %w[system georgia helvetica verdana].each do |font|
      @setting.email_font_family = font
      assert @setting.valid?, "#{font} should be valid"
    end
  end

  test "invalid font family rejected" do
    @setting.email_font_family = "comic_sans"
    assert_not @setting.valid?
    assert @setting.errors[:email_font_family].any?
  end

  test "email_font_stack returns correct stack for system" do
    @setting.email_font_family = "system"
    assert_includes @setting.email_font_stack, "BlinkMacSystemFont"
  end

  test "email_font_stack returns correct stack for georgia" do
    @setting.email_font_family = "georgia"
    assert_includes @setting.email_font_stack, "Georgia"
  end

  test "email_font_stack defaults to system when nil" do
    @setting.email_font_family = nil
    assert_includes @setting.email_font_stack, "BlinkMacSystemFont"
  end

  test "defaults are set correctly" do
    assert_equal "#18181b", @setting.email_accent_color
    assert_equal "#f4f4f5", @setting.email_background_color
    assert_equal "#3f3f46", @setting.email_body_text_color
    assert_equal "#18181b", @setting.email_heading_color
    assert_equal "system", @setting.email_font_family
    assert_equal "minimal", @setting.email_default_template
  end
end
