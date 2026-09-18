class CreateMailingLists < ActiveRecord::Migration[8.1]
  def up
    create_table :mailing_lists do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.string :frequency
      t.boolean :active, null: false, default: true
      t.boolean :subscribe_by_default, null: false, default: false

      t.timestamps
    end
    add_index :mailing_lists, :slug, unique: true

    create_table :mailing_list_subscriptions do |t|
      t.references :mailing_list, null: false, foreign_key: true
      t.references :subscriber, null: false, foreign_key: true, index: false

      t.timestamps
    end
    add_index :mailing_list_subscriptions, [ :subscriber_id, :mailing_list_id ], unique: true

    create_table :mailing_list_posts do |t|
      t.references :mailing_list, null: false, foreign_key: true
      t.references :post, null: false, foreign_key: true, index: false

      t.timestamps
    end
    add_index :mailing_list_posts, [ :post_id, :mailing_list_id ], unique: true

    add_reference :newsletters, :mailing_list, foreign_key: true
    add_column :posts, :subscribers_notified_at, :datetime

    migrate_to_default_list
  end

  def down
    remove_column :posts, :subscribers_notified_at
    remove_reference :newsletters, :mailing_list, foreign_key: true
    drop_table :mailing_list_posts
    drop_table :mailing_list_subscriptions
    drop_table :mailing_lists
  end

  private

  # Before this migration every subscriber got every post. Folding everyone and
  # every post into one default list keeps that behavior after upgrading, and
  # stamping already-published posts as notified stops an unpublish/republish
  # from emailing them a second time.
  def migrate_to_default_list
    now = connection.quote(Time.current)

    execute <<~SQL
      INSERT INTO mailing_lists (name, slug, active, subscribe_by_default, created_at, updated_at)
      VALUES ('Newsletter', 'newsletter', 1, 1, #{now}, #{now})
    SQL
    list_id = select_value("SELECT id FROM mailing_lists WHERE slug = 'newsletter'")

    execute <<~SQL
      INSERT INTO mailing_list_subscriptions (mailing_list_id, subscriber_id, created_at, updated_at)
      SELECT #{list_id}, id, #{now}, #{now} FROM subscribers WHERE unsubscribed_at IS NULL
    SQL

    execute <<~SQL
      INSERT INTO mailing_list_posts (mailing_list_id, post_id, created_at, updated_at)
      SELECT #{list_id}, id, #{now}, #{now} FROM posts
    SQL

    execute "UPDATE posts SET subscribers_notified_at = COALESCE(published_at, #{now}) WHERE status = 2"
  end
end
