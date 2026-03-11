class CreateSegments < ActiveRecord::Migration[8.1]
  def change
    create_table :segments do |t|
      t.string :name, null: false
      t.text :description
      t.json :filter_criteria, null: false, default: {}

      t.timestamps
    end
  end
end
