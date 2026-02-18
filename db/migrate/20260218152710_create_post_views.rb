class CreatePostViews < ActiveRecord::Migration[8.1]
  def change
    create_table :post_views do |t|
      t.references :post, null: false, foreign_key: true
      t.string :ip_hash
      t.string :user_agent
      t.string :referrer
      t.string :source

      t.timestamps
    end

    add_index :post_views, :created_at
    add_index :post_views, [ :post_id, :created_at ]
  end
end
