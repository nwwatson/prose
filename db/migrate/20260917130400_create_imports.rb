class CreateImports < ActiveRecord::Migration[8.1]
  def change
    create_table :imports do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :source, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.json :stats, null: false, default: {}
      t.text :error_message
      t.datetime :completed_at

      t.timestamps
    end

    add_index :imports, :created_at
  end
end
