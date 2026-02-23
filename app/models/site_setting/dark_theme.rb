module SiteSetting::DarkTheme
  extend ActiveSupport::Concern

  DARK_THEMES = {
    "midnight" => { name: "Midnight",  bg: "#1a1a2e", text: "#e0def4", accent: "#7ba4cc" },
    "charcoal" => { name: "Charcoal",  bg: "#1e1e1e", text: "#d4d4d4", accent: "#6cb6ff" },
    "ocean"    => { name: "Ocean",     bg: "#0d1b2a", text: "#e0e1dd", accent: "#90bce0" },
    "forest"   => { name: "Forest",    bg: "#1a2e1a", text: "#d4e0d4", accent: "#8fbc8f" },
    "custom"   => { name: "Custom",    bg: nil,       text: nil,       accent: nil }
  }.freeze

  included do
    validates :dark_theme, inclusion: { in: DARK_THEMES.keys }
    validates :dark_bg_color, :dark_text_color, :dark_accent_color,
              format: { with: /\A#[0-9a-fA-F]{6}\z/, message: "must be a valid hex color (e.g. #1a1a2e)" },
              if: -> { dark_theme == "custom" }
  end

  def dark_bg_hex
    dark_theme == "custom" ? dark_bg_color : DARK_THEMES.dig(dark_theme, :bg) || DARK_THEMES["midnight"][:bg]
  end

  def dark_text_hex
    dark_theme == "custom" ? dark_text_color : DARK_THEMES.dig(dark_theme, :text) || DARK_THEMES["midnight"][:text]
  end

  def dark_accent_hex
    dark_theme == "custom" ? dark_accent_color : DARK_THEMES.dig(dark_theme, :accent) || DARK_THEMES["midnight"][:accent]
  end
end
