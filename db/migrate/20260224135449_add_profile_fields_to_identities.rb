class AddProfileFieldsToIdentities < ActiveRecord::Migration[8.1]
  def change
    add_column :identities, :bio, :text
    add_column :identities, :website_url, :string
    add_column :identities, :twitter_handle, :string
    add_column :identities, :github_handle, :string
  end
end
