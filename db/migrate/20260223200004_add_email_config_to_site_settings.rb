class AddEmailConfigToSiteSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :site_settings, :email_provider, :string, default: "smtp"
    add_column :site_settings, :sendgrid_api_key, :string
  end
end
