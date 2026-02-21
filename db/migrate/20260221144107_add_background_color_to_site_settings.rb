class AddBackgroundColorToSiteSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :site_settings, :background_color, :string, default: "cream"
  end
end
