class CreateIdentities < ActiveRecord::Migration[8.1]
  def change
    create_table :identities do |t|
      t.string :name, null: false
      t.string :handle
      t.json :settings, default: {}
      t.timestamps
    end

    add_index :identities, :handle, unique: true
  end
end
