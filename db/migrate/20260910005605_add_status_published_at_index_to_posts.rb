class AddStatusPublishedAtIndexToPosts < ActiveRecord::Migration[8.1]
  def change
    add_index :posts, [ :status, :published_at ]
  end
end
