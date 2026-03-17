class RemoveScheduledAtFromPosts < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE posts
      SET published_at = scheduled_at
      WHERE scheduled_at IS NOT NULL AND published_at IS NULL
    SQL

    remove_column :posts, :scheduled_at

    # SQLite drops triggers when it recreates a table during remove_column.
    # Recreate the FTS5 triggers so full-text search stays in sync.
    execute <<~SQL
      CREATE TRIGGER IF NOT EXISTS posts_fts_insert AFTER INSERT ON posts BEGIN
        INSERT INTO posts_fts(rowid, title, subtitle, body_plain)
        VALUES (NEW.id, NEW.title, NEW.subtitle, NEW.body_plain);
      END;
    SQL

    execute <<~SQL
      CREATE TRIGGER IF NOT EXISTS posts_fts_update AFTER UPDATE ON posts BEGIN
        INSERT INTO posts_fts(posts_fts, rowid, title, subtitle, body_plain)
        VALUES ('delete', OLD.id, OLD.title, OLD.subtitle, OLD.body_plain);
        INSERT INTO posts_fts(rowid, title, subtitle, body_plain)
        VALUES (NEW.id, NEW.title, NEW.subtitle, NEW.body_plain);
      END;
    SQL

    execute <<~SQL
      CREATE TRIGGER IF NOT EXISTS posts_fts_delete AFTER DELETE ON posts BEGIN
        INSERT INTO posts_fts(posts_fts, rowid, title, subtitle, body_plain)
        VALUES ('delete', OLD.id, OLD.title, OLD.subtitle, OLD.body_plain);
      END;
    SQL
  end

  def down
    add_column :posts, :scheduled_at, :datetime

    execute <<~SQL
      UPDATE posts
      SET scheduled_at = published_at
      WHERE status = 1 AND published_at IS NOT NULL
    SQL
  end
end
