class AddSiteUrlToImports < ActiveRecord::Migration[8.1]
  def change
    add_column :imports, :site_url, :string
  end
end
