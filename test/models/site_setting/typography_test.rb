require "test_helper"

class SiteSetting::TypographyTest < ActiveSupport::TestCase
  setup do
    @setting = SiteSetting.current
  end

  # --- Defaults match current hardcoded fonts ---

  test "defaults match current hardcoded fonts" do
    assert_equal "Playfair Display", @setting.heading_font
    assert_equal "Source Serif 4", @setting.subtitle_font
    assert_equal "Source Serif 4", @setting.body_font
    assert_equal 2.25, @setting.heading_font_size.to_f
    assert_equal 1.25, @setting.subtitle_font_size.to_f
    assert_in_delta 1.125, @setting.body_font_size.to_f, 0.01
  end

  # --- Font name validation ---

  test "accepts known Google Fonts" do
    @setting.heading_font = "Inter"
    @setting.subtitle_font = "Lora"
    @setting.body_font = "Merriweather"
    assert @setting.valid?
  end

  test "rejects unknown font names" do
    @setting.heading_font = "Comic Sans MS"
    assert_not @setting.valid?
    assert @setting.errors[:heading_font].any?
  end

  test "rejects unknown subtitle font" do
    @setting.subtitle_font = "Papyrus"
    assert_not @setting.valid?
    assert @setting.errors[:subtitle_font].any?
  end

  test "rejects unknown body font" do
    @setting.body_font = "Wingdings"
    assert_not @setting.valid?
    assert @setting.errors[:body_font].any?
  end

  # --- Font size validation ---

  test "accepts valid font sizes" do
    @setting.heading_font_size = 3.0
    @setting.subtitle_font_size = 1.5
    @setting.body_font_size = 1.0
    assert @setting.valid?
  end

  test "rejects font size below minimum" do
    @setting.heading_font_size = 0.5
    assert_not @setting.valid?
    assert @setting.errors[:heading_font_size].any?
  end

  test "rejects font size above maximum" do
    @setting.body_font_size = 7.0
    assert_not @setting.valid?
    assert @setting.errors[:body_font_size].any?
  end

  test "accepts boundary font sizes" do
    @setting.heading_font_size = 0.75
    @setting.subtitle_font_size = 6.0
    @setting.body_font_size = 0.75
    assert @setting.valid?
  end

  # --- google_fonts_url ---

  test "google_fonts_url includes all selected fonts" do
    @setting.heading_font = "Inter"
    @setting.subtitle_font = "Lora"
    @setting.body_font = "Merriweather"

    url = @setting.google_fonts_url
    assert_includes url, "family=Inter"
    assert_includes url, "family=Lora"
    assert_includes url, "family=Merriweather"
    assert_includes url, "display=swap"
  end

  test "google_fonts_url deduplicates fonts" do
    @setting.heading_font = "Inter"
    @setting.subtitle_font = "Inter"
    @setting.body_font = "Lora"

    url = @setting.google_fonts_url
    assert_equal 1, url.scan("family=Inter").count
  end

  test "google_fonts_url encodes spaces as plus" do
    url = @setting.google_fonts_url
    assert_includes url, "Playfair+Display"
    assert_includes url, "Source+Serif+4"
  end

  # --- fallback_for ---

  test "fallback_for returns serif stack for serif fonts" do
    assert_equal "Georgia, serif", @setting.fallback_for("Playfair Display")
    assert_equal "Georgia, serif", @setting.fallback_for("Merriweather")
  end

  test "fallback_for returns sans-serif stack for sans fonts" do
    assert_equal "system-ui, sans-serif", @setting.fallback_for("Inter")
    assert_equal "system-ui, sans-serif", @setting.fallback_for("Roboto")
  end

  test "fallback_for returns monospace stack for monospace fonts" do
    assert_equal "'Courier New', monospace", @setting.fallback_for("JetBrains Mono")
  end

  test "fallback_for defaults to serif for unknown fonts" do
    assert_equal "Georgia, serif", @setting.fallback_for("Unknown Font")
  end
end
