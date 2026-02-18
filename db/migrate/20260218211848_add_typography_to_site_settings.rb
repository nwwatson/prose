class AddTypographyToSiteSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :site_settings, :heading_font, :string, default: "Playfair Display"
    add_column :site_settings, :subtitle_font, :string, default: "Source Serif 4"
    add_column :site_settings, :body_font, :string, default: "Source Serif 4"
    add_column :site_settings, :heading_font_size, :decimal, precision: 4, scale: 2, default: 2.25
    add_column :site_settings, :subtitle_font_size, :decimal, precision: 4, scale: 2, default: 1.25
    add_column :site_settings, :body_font_size, :decimal, precision: 4, scale: 2, default: 1.125
  end
end
