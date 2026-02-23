class CreateNewsletterDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :newsletter_deliveries do |t|
      t.references :newsletter, null: false, foreign_key: true
      t.references :subscriber, null: false, foreign_key: true
      t.datetime :sent_at

      t.timestamps
    end

    add_index :newsletter_deliveries, [ :newsletter_id, :subscriber_id ], unique: true
  end
end
