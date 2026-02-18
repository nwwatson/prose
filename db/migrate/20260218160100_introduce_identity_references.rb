class IntroduceIdentityReferences < ActiveRecord::Migration[8.1]
  def up
    # Add nullable identity_id to all tables
    add_reference :users, :identity, foreign_key: true
    add_reference :subscribers, :identity, foreign_key: true
    add_reference :comments, :identity, foreign_key: true
    add_reference :loves, :identity, foreign_key: true

    # Migrate User data
    execute <<~SQL
      INSERT INTO identities (name, created_at, updated_at)
      SELECT display_name, created_at, updated_at FROM users
    SQL

    # Link users to their identities by matching on display_name
    execute <<~SQL
      UPDATE users SET identity_id = (
        SELECT identities.id FROM identities
        WHERE identities.name = users.display_name
        AND identities.handle IS NULL
        AND identities.rowid IN (
          SELECT MIN(i2.rowid) FROM identities i2
          WHERE i2.name = users.display_name AND i2.handle IS NULL
        )
      )
    SQL

    # Migrate Subscriber data
    execute <<~SQL
      INSERT INTO identities (name, handle, created_at, updated_at)
      SELECT
        COALESCE(handle, SUBSTR(email, 1, INSTR(email, '@') - 1)),
        handle,
        created_at,
        updated_at
      FROM subscribers
    SQL

    # Link subscribers to their identities by matching on email-derived name or handle
    execute <<~SQL
      UPDATE subscribers SET identity_id = (
        SELECT identities.id FROM identities
        WHERE (
          (subscribers.handle IS NOT NULL AND identities.handle = subscribers.handle)
          OR
          (subscribers.handle IS NULL AND identities.name = SUBSTR(subscribers.email, 1, INSTR(subscribers.email, '@') - 1) AND identities.handle IS NULL AND identities.id NOT IN (SELECT identity_id FROM users WHERE identity_id IS NOT NULL))
        )
        LIMIT 1
      )
    SQL

    # Link comments to identities via subscribers
    execute <<~SQL
      UPDATE comments SET identity_id = (
        SELECT subscribers.identity_id FROM subscribers
        WHERE subscribers.id = comments.subscriber_id
      )
    SQL

    # Link loves to identities via subscribers
    execute <<~SQL
      UPDATE loves SET identity_id = (
        SELECT subscribers.identity_id FROM subscribers
        WHERE subscribers.id = loves.subscriber_id
      )
    SQL

    # Enforce NOT NULL constraints
    change_column_null :users, :identity_id, false
    change_column_null :subscribers, :identity_id, false
    change_column_null :comments, :identity_id, false
    change_column_null :loves, :identity_id, false

    # Remove old subscriber foreign keys and columns from comments and loves
    remove_index :loves, [ :post_id, :subscriber_id ]
    remove_reference :comments, :subscriber, foreign_key: true
    remove_reference :loves, :subscriber, foreign_key: true

    # Add new unique index for loves
    add_index :loves, [ :post_id, :identity_id ], unique: true

    # Remove migrated columns
    remove_index :subscribers, :handle
    remove_column :subscribers, :handle, :string
    remove_column :users, :display_name, :string
  end

  def down
    # Add back removed columns
    add_column :users, :display_name, :string
    add_column :subscribers, :handle, :string
    add_index :subscribers, :handle, unique: true

    # Restore data from identities
    execute <<~SQL
      UPDATE users SET display_name = (
        SELECT identities.name FROM identities WHERE identities.id = users.identity_id
      )
    SQL
    change_column_null :users, :display_name, false

    execute <<~SQL
      UPDATE subscribers SET handle = (
        SELECT identities.handle FROM identities WHERE identities.id = subscribers.identity_id
      )
    SQL

    # Add back subscriber references
    add_reference :comments, :subscriber, foreign_key: true
    add_reference :loves, :subscriber, foreign_key: true

    # Restore subscriber_id on comments and loves
    execute <<~SQL
      UPDATE comments SET subscriber_id = (
        SELECT subscribers.id FROM subscribers WHERE subscribers.identity_id = comments.identity_id
      )
    SQL

    execute <<~SQL
      UPDATE loves SET subscriber_id = (
        SELECT subscribers.id FROM subscribers WHERE subscribers.identity_id = loves.identity_id
      )
    SQL

    change_column_null :comments, :subscriber_id, false
    change_column_null :loves, :subscriber_id, false

    # Remove identity references
    remove_index :loves, [ :post_id, :identity_id ]
    add_index :loves, [ :post_id, :subscriber_id ], unique: true

    remove_reference :users, :identity, foreign_key: true
    remove_reference :subscribers, :identity, foreign_key: true
    remove_reference :comments, :identity, foreign_key: true
    remove_reference :loves, :identity, foreign_key: true
  end
end
