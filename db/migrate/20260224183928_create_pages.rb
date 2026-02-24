class CreatePages < ActiveRecord::Migration[8.1]
  def change
    create_table :pages do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.integer :status, default: 0, null: false
      t.text :meta_description
      t.boolean :show_in_navigation, default: false, null: false
      t.integer :position, default: 0, null: false
      t.datetime :published_at
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    add_index :pages, :slug, unique: true
    add_index :pages, :status
  end
end
