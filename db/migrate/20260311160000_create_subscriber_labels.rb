class CreateSubscriberLabels < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriber_labels do |t|
      t.string :name, null: false
      t.string :color, null: false, default: "#6B7280"

      t.timestamps
    end

    add_index :subscriber_labels, :name, unique: true
  end
end
