class CreateXPosts < ActiveRecord::Migration[8.1]
  def change
    create_table :x_posts do |t|
      t.string :url, null: false
      t.text :embed_html
      t.string :author_name
      t.string :author_username

      t.timestamps
    end

    add_index :x_posts, :url, unique: true
  end
end
