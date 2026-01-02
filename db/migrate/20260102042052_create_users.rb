class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email
      t.string :password_digest
      t.string :name
      t.datetime :confirmed_at
      t.string :confirmation_token
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.string :remember_token
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.integer :sign_in_count, default: 0
      t.integer :failed_attempts, default: 0
      t.datetime :locked_at

      t.timestamps
    end
    add_index :users, :email, unique: true
  end
end
