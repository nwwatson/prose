class CreateWebhooks < ActiveRecord::Migration[8.1]
  def change
    create_table :webhooks do |t|
      t.string :url, null: false
      t.json :events, null: false, default: []
      t.string :signing_secret
      t.boolean :active, null: false, default: true
      t.integer :consecutive_failures, null: false, default: 0
      t.datetime :last_triggered_at
      t.integer :last_response_code

      t.timestamps
    end
  end
end
