class CreatePublications < ActiveRecord::Migration[8.1]
  def change
    create_table :publications do |t|
      t.string :name, null: false
      t.text :tagline
      t.string :slug, null: false
      t.text :description
      t.string :custom_domain
      t.text :custom_css
      t.text :settings
      t.text :social_links
      t.string :language, default: 'en'
      t.string :timezone, default: 'UTC'
      t.boolean :active, default: true, null: false
      t.references :account, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_index :publications, :slug, unique: true
    add_index :publications, :custom_domain, unique: true
    add_index :publications, [ :account_id, :active ]
  end
end
