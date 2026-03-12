class AddThemeModeToSiteSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :site_settings, :theme_mode, :string, default: "visitor_choice", null: false
  end
end
