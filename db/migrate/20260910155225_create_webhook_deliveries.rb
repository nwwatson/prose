class CreateWebhookDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :webhook_deliveries do |t|
      t.references :webhook, null: false, foreign_key: true
      t.string :event, null: false
      t.json :payload, null: false, default: {}
      t.integer :response_code
      t.boolean :success, null: false, default: false
      t.text :error_message
      t.datetime :attempted_at, null: false

      t.timestamps
    end

    add_index :webhook_deliveries, [ :webhook_id, :attempted_at ]
  end
end
