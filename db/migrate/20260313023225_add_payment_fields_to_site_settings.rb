class AddPaymentFieldsToSiteSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :site_settings, :stripe_secret_key, :string
    add_column :site_settings, :stripe_publishable_key, :string
    add_column :site_settings, :stripe_webhook_secret, :string
    add_column :site_settings, :payments_currency, :string, default: "usd"
  end
end
