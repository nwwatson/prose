module SiteSetting::Appearance
  extend ActiveSupport::Concern

  BACKGROUND_COLORS = {
    "cream" => { name: "Cream", hex: "#faf7f2" },
    "snow" => { name: "Snow White", hex: "#fafafa" },
    "warm_gray" => { name: "Warm Gray", hex: "#f5f3f0" },
    "cool_gray" => { name: "Cool Gray", hex: "#f0f2f4" },
    "linen" => { name: "Soft Linen", hex: "#faf5ef" },
    "sage" => { name: "Pale Sage", hex: "#f2f5f0" },
    "lavender" => { name: "Pale Lavender", hex: "#f3f0f5" },
    "soft_blue" => { name: "Soft Blue", hex: "#eff3f8" }
  }.freeze

  included do
    validates :background_color, inclusion: { in: BACKGROUND_COLORS.keys }
  end

  def background_hex
    BACKGROUND_COLORS.dig(background_color, :hex) || BACKGROUND_COLORS["cream"][:hex]
  end
end
