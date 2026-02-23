class CreateNewsletters < ActiveRecord::Migration[8.1]
  def change
    create_table :newsletters do |t|
      t.string :title, null: false
      t.integer :status, null: false, default: 0
      t.datetime :sent_at
      t.datetime :scheduled_for
      t.integer :recipients_count, default: 0
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :newsletters, :status
    add_index :newsletters, :scheduled_for
  end
end
