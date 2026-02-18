class CreateSiteSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :site_settings do |t|
      t.string :site_name, null: false, default: "Prose"
      t.text :site_description, default: ""
      t.timestamps
    end
  end
end
