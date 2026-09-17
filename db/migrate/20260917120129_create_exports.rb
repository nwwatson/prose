class CreateExports < ActiveRecord::Migration[8.1]
  def change
    create_table :exports do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :format, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.text :error_message
      t.datetime :completed_at

      t.timestamps
    end

    add_index :exports, :created_at
  end
end
