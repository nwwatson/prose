class AddImageModelAndOpenaiKeyToSiteSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :site_settings, :openai_api_key, :string
    add_column :site_settings, :image_model, :string, default: "imagen-4.0-generate-001"
  end
end
