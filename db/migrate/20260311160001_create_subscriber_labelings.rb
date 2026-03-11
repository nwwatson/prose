class CreateSubscriberLabelings < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriber_labelings do |t|
      t.references :subscriber, null: false, foreign_key: true
      t.references :subscriber_label, null: false, foreign_key: true

      t.timestamps
    end

    add_index :subscriber_labelings, [ :subscriber_id, :subscriber_label_id ], unique: true, name: "idx_subscriber_labelings_uniqueness"
  end
end
