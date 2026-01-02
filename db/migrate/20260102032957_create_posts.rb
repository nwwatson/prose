class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :summary
      t.string :status, null: false, default: "draft"
      t.datetime :scheduled_at
      t.datetime :published_at
      t.string :meta_title
      t.text :meta_description
      t.integer :reading_time, default: 0
      t.integer :view_count, default: 0
      t.boolean :featured, default: false, null: false
      t.boolean :pinned, default: false, null: false
      t.references :publication, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_index :posts, :slug
    add_index :posts, :status
    add_index :posts, :published_at
    add_index :posts, [:publication_id, :status]
    add_index :posts, [:publication_id, :published_at]
    add_index :posts, [:publication_id, :slug], unique: true
  end
end
