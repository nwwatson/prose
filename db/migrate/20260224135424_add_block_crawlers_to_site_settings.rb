class AddBlockCrawlersToSiteSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :site_settings, :block_crawlers, :boolean, default: false, null: false
  end
end
