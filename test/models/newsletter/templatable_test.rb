require "test_helper"

class Newsletter::TemplatableTest < ActiveSupport::TestCase
  setup do
    @newsletter = newsletters(:draft_newsletter)
  end

  test "resolved_template uses newsletter value when set" do
    @newsletter.template = "editorial"
    assert_equal "editorial", @newsletter.resolved_template
  end

  test "resolved_template falls back to site default" do
    @newsletter.template = nil
    SiteSetting.current.update!(email_default_template: "branded")
    assert_equal "branded", @newsletter.resolved_template
  end

  test "resolved_template falls back to minimal when no site default" do
    @newsletter.template = nil
    SiteSetting.current.update!(email_default_template: "")
    assert_equal "minimal", @newsletter.resolved_template
  end

  test "resolved_accent_color uses newsletter value when set" do
    @newsletter.accent_color = "#ff0000"
    assert_equal "#ff0000", @newsletter.resolved_accent_color
  end

  test "resolved_accent_color falls back to site default" do
    @newsletter.accent_color = nil
    SiteSetting.current.update!(email_accent_color: "#00ff00")
    assert_equal "#00ff00", @newsletter.resolved_accent_color
  end

  test "resolved_preheader_text uses newsletter value when set" do
    @newsletter.preheader_text = "Custom preview"
    assert_equal "Custom preview", @newsletter.resolved_preheader_text
  end

  test "resolved_preheader_text falls back to site default" do
    @newsletter.preheader_text = nil
    SiteSetting.current.update!(email_preheader_text: "Default preview")
    assert_equal "Default preview", @newsletter.resolved_preheader_text
  end

  test "email_settings returns complete hash" do
    settings = @newsletter.email_settings
    assert_kind_of Hash, settings
    %i[template accent_color preheader_text background_color body_text_color
       heading_color font_family footer_text site_name logo_url
       social_twitter social_github social_linkedin social_website].each do |key|
      assert settings.key?(key), "email_settings should include :#{key}"
    end
  end

  test "email_settings uses site_name from SiteSetting" do
    assert_equal SiteSetting.current.site_name, @newsletter.email_settings[:site_name]
  end

  test "validates template inclusion" do
    @newsletter.template = "editorial"
    assert @newsletter.valid?

    @newsletter.template = "nonexistent"
    assert_not @newsletter.valid?
    assert @newsletter.errors[:template].any?
  end

  test "allows nil template" do
    @newsletter.template = nil
    assert @newsletter.valid?
  end

  test "validates accent_color hex format" do
    @newsletter.accent_color = "#aabbcc"
    assert @newsletter.valid?

    @newsletter.accent_color = "notahex"
    assert_not @newsletter.valid?
  end

  test "allows nil accent_color" do
    @newsletter.accent_color = nil
    assert @newsletter.valid?
  end

  test "validates preheader_text max length" do
    @newsletter.preheader_text = "a" * 150
    assert @newsletter.valid?

    @newsletter.preheader_text = "a" * 151
    assert_not @newsletter.valid?
  end
end
