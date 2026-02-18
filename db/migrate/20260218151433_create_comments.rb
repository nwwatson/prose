class CreateComments < ActiveRecord::Migration[8.1]
  def change
    create_table :comments do |t|
      t.references :post, null: false, foreign_key: true
      t.references :subscriber, null: false, foreign_key: true
      t.references :parent_comment, foreign_key: { to_table: :comments }
      t.text :body, null: false
      t.boolean :approved, null: false, default: true

      t.timestamps
    end
  end
end
