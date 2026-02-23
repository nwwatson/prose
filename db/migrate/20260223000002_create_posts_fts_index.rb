class CreatePostsFtsIndex < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      CREATE VIRTUAL TABLE posts_fts USING fts5(
        title,
        subtitle,
        body_plain,
        content='posts',
        content_rowid='id'
      );
    SQL

    execute <<~SQL
      CREATE TRIGGER posts_fts_insert AFTER INSERT ON posts BEGIN
        INSERT INTO posts_fts(rowid, title, subtitle, body_plain)
        VALUES (NEW.id, NEW.title, NEW.subtitle, NEW.body_plain);
      END;
    SQL

    execute <<~SQL
      CREATE TRIGGER posts_fts_update AFTER UPDATE ON posts BEGIN
        INSERT INTO posts_fts(posts_fts, rowid, title, subtitle, body_plain)
        VALUES ('delete', OLD.id, OLD.title, OLD.subtitle, OLD.body_plain);
        INSERT INTO posts_fts(rowid, title, subtitle, body_plain)
        VALUES (NEW.id, NEW.title, NEW.subtitle, NEW.body_plain);
      END;
    SQL

    execute <<~SQL
      CREATE TRIGGER posts_fts_delete AFTER DELETE ON posts BEGIN
        INSERT INTO posts_fts(posts_fts, rowid, title, subtitle, body_plain)
        VALUES ('delete', OLD.id, OLD.title, OLD.subtitle, OLD.body_plain);
      END;
    SQL
  end

  def down
    execute "DROP TRIGGER IF EXISTS posts_fts_delete"
    execute "DROP TRIGGER IF EXISTS posts_fts_update"
    execute "DROP TRIGGER IF EXISTS posts_fts_insert"
    execute "DROP TABLE IF EXISTS posts_fts"
  end
end
