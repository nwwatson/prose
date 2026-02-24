class AddLocaleToSiteSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :site_settings, :locale, :string, default: "en", null: false
  end
end
