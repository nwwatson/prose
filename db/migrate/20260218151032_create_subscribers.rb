class CreateSubscribers < ActiveRecord::Migration[8.1]
  def change
    create_table :subscribers do |t|
      t.string :email, null: false
      t.string :handle
      t.datetime :confirmed_at
      t.string :auth_token
      t.datetime :auth_token_sent_at

      t.timestamps
    end

    add_index :subscribers, :email, unique: true
    add_index :subscribers, :handle, unique: true
    add_index :subscribers, :auth_token, unique: true
  end
end
