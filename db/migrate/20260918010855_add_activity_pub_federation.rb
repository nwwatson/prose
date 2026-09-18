class AddActivityPubFederation < ActiveRecord::Migration[8.1]
  def change
    change_table :site_settings, bulk: true do |t|
      t.boolean :activitypub_enabled, default: false, null: false
      t.string :activitypub_username, default: "blog", null: false
      t.text :activitypub_private_key
      t.text :activitypub_public_key
    end

    create_table :fediverse_actors do |t|
      t.string :uri, null: false
      t.string :inbox_url
      t.string :shared_inbox_url
      t.string :key_id
      t.text :public_key_pem
      t.string :username
      t.string :name
      t.string :profile_url
      t.datetime :followed_at
      t.datetime :fetched_at
      t.references :identity, foreign_key: true
      t.timestamps
    end
    add_index :fediverse_actors, :uri, unique: true
    add_index :fediverse_actors, :key_id
    add_index :fediverse_actors, :followed_at

    create_table :fediverse_likes do |t|
      t.references :post, null: false, foreign_key: true
      t.references :fediverse_actor, null: false, foreign_key: true
      t.string :activity_uri
      t.timestamps
    end
    add_index :fediverse_likes, [ :post_id, :fediverse_actor_id ], unique: true

    add_column :comments, :activitypub_uri, :string
    add_index :comments, :activitypub_uri, unique: true
  end
end
