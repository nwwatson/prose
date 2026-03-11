class AddReferrerTrackingToPostViews < ActiveRecord::Migration[8.1]
  def change
    add_column :post_views, :referrer_domain, :string
    add_column :post_views, :utm_source, :string
    add_column :post_views, :utm_medium, :string
    add_column :post_views, :utm_campaign, :string

    add_index :post_views, :referrer_domain
    add_index :post_views, :utm_source
    add_index :post_views, :utm_campaign
  end
end
