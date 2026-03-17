class RemoveScheduledAtFromPosts < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE posts
      SET published_at = scheduled_at
      WHERE scheduled_at IS NOT NULL AND published_at IS NULL
    SQL

    remove_column :posts, :scheduled_at
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
