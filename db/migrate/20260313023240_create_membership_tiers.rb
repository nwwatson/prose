class CreateMembershipTiers < ActiveRecord::Migration[8.1]
  def change
    create_table :membership_tiers do |t|
      t.string :name, null: false
      t.text :description
      t.integer :price_cents, null: false
      t.string :currency, null: false, default: "usd"
      t.integer :interval, null: false, default: 0
      t.string :stripe_price_id
      t.string :stripe_product_id
      t.boolean :active, null: false, default: true
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    add_index :membership_tiers, :active
    add_index :membership_tiers, :stripe_price_id, unique: true
    add_index :membership_tiers, :stripe_product_id, unique: true
  end
end
