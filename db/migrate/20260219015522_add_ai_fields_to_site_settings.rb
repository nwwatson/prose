class AddAiFieldsToSiteSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :site_settings, :claude_api_key, :string
    add_column :site_settings, :gemini_api_key, :string
    add_column :site_settings, :ai_model, :string, default: "claude-sonnet-4-5-20250929"
    add_column :site_settings, :ai_max_tokens, :integer, default: 4096
  end
end
