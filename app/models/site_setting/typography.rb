module SiteSetting::Typography
  extend ActiveSupport::Concern

  FONT_CATEGORIES = {
    # Serif
    "Playfair Display" => "serif",
    "Source Serif 4" => "serif",
    "Merriweather" => "serif",
    "Lora" => "serif",
    "PT Serif" => "serif",
    "Crimson Text" => "serif",
    "Libre Baskerville" => "serif",
    "EB Garamond" => "serif",
    "Cormorant Garamond" => "serif",
    "Bitter" => "serif",
    # Sans-serif
    "Inter" => "sans-serif",
    "Open Sans" => "sans-serif",
    "Roboto" => "sans-serif",
    "Lato" => "sans-serif",
    "Montserrat" => "sans-serif",
    "Raleway" => "sans-serif",
    "Nunito" => "sans-serif",
    "Work Sans" => "sans-serif",
    "DM Sans" => "sans-serif",
    "Plus Jakarta Sans" => "sans-serif",
    # Display
    "Abril Fatface" => "serif",
    "Oswald" => "sans-serif",
    "Bebas Neue" => "sans-serif",
    # Monospace
    "JetBrains Mono" => "monospace",
    "Fira Code" => "monospace"
  }.freeze

  GOOGLE_FONTS = FONT_CATEGORIES.keys.freeze

  FALLBACK_STACKS = {
    "serif" => "Georgia, serif",
    "sans-serif" => "system-ui, sans-serif",
    "monospace" => "'Courier New', monospace"
  }.freeze

  included do
    validates :heading_font, :subtitle_font, :body_font, inclusion: { in: GOOGLE_FONTS }, allow_nil: true
    validates :heading_font_size, :subtitle_font_size, :body_font_size,
              numericality: { greater_than_or_equal_to: 0.75, less_than_or_equal_to: 6.0 }, allow_nil: true
  end

  def google_fonts_url
    fonts = [ heading_font, subtitle_font, body_font ].compact.uniq
    return if fonts.empty?

    families = fonts.map { |f| "family=#{f.gsub(' ', '+')}" }.join("&")
    "https://fonts.googleapis.com/css2?#{families}&display=swap"
  end

  def fallback_for(font_name)
    category = FONT_CATEGORIES[font_name] || "serif"
    FALLBACK_STACKS[category]
  end

  def font_family_value(font_name)
    "\"#{font_name}\", #{fallback_for(font_name)}"
  end
end
