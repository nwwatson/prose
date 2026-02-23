class AddDarkThemeToSiteSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :site_settings, :dark_theme, :string, default: "midnight"
    add_column :site_settings, :dark_bg_color, :string, default: "#1a1a2e"
    add_column :site_settings, :dark_text_color, :string, default: "#e0def4"
    add_column :site_settings, :dark_accent_color, :string, default: "#7ba4cc"
  end
end
