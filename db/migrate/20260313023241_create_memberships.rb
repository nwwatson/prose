class CreateMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :memberships do |t|
      t.references :subscriber, null: false, foreign_key: true
      t.references :membership_tier, null: false, foreign_key: true
      t.string :stripe_subscription_id
      t.string :stripe_customer_id
      t.integer :status, null: false, default: 0
      t.datetime :current_period_start
      t.datetime :current_period_end
      t.datetime :canceled_at
      t.timestamps
    end

    add_index :memberships, :stripe_subscription_id, unique: true
    add_index :memberships, :stripe_customer_id
    add_index :memberships, :status
  end
end
