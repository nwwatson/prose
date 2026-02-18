class CreateLoves < ActiveRecord::Migration[8.1]
  def change
    create_table :loves do |t|
      t.references :post, null: false, foreign_key: true
      t.references :subscriber, null: false, foreign_key: true

      t.timestamps
    end

    add_index :loves, [ :post_id, :subscriber_id ], unique: true
  end
end
