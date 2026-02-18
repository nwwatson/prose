class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.string :title, null: false
      t.string :subtitle
      t.string :slug, null: false
      t.integer :status, null: false, default: 0
      t.datetime :published_at
      t.datetime :scheduled_at
      t.boolean :featured, null: false, default: false
      t.integer :reading_time_minutes, default: 0
      t.references :category, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :posts, :slug, unique: true
    add_index :posts, :status
    add_index :posts, :published_at
  end
end
