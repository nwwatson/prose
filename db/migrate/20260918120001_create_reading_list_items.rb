class CreateReadingListItems < ActiveRecord::Migration[8.1]
  def change
    create_table :reading_list_items do |t|
      t.references :identity, null: false, foreign_key: true, index: false
      t.references :post, null: false, foreign_key: true

      t.timestamps
    end

    # Leading identity_id serves both the uniqueness check and "my list, newest first".
    add_index :reading_list_items, [ :identity_id, :post_id ], unique: true
  end
end
