class AddWhenClauseToPostsFtsUpdateTrigger < ActiveRecord::Migration[8.1]
  def up
    execute "DROP TRIGGER IF EXISTS posts_fts_update"

    execute <<~SQL
      CREATE TRIGGER posts_fts_update AFTER UPDATE ON posts
      WHEN OLD.title IS NOT NEW.title OR OLD.subtitle IS NOT NEW.subtitle OR OLD.body_plain IS NOT NEW.body_plain
      BEGIN
        INSERT INTO posts_fts(posts_fts, rowid, title, subtitle, body_plain)
        VALUES ('delete', OLD.id, OLD.title, OLD.subtitle, OLD.body_plain);
        INSERT INTO posts_fts(rowid, title, subtitle, body_plain)
        VALUES (NEW.id, NEW.title, NEW.subtitle, NEW.body_plain);
      END;
    SQL
  end

  def down
    execute "DROP TRIGGER IF EXISTS posts_fts_update"

    execute <<~SQL
      CREATE TRIGGER posts_fts_update AFTER UPDATE ON posts BEGIN
        INSERT INTO posts_fts(posts_fts, rowid, title, subtitle, body_plain)
        VALUES ('delete', OLD.id, OLD.title, OLD.subtitle, OLD.body_plain);
        INSERT INTO posts_fts(rowid, title, subtitle, body_plain)
        VALUES (NEW.id, NEW.title, NEW.subtitle, NEW.body_plain);
      END;
    SQL
  end
end
