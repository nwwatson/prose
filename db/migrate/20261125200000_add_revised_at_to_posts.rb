# `revised_at` marks the last save that changed something readers and
# integrations see (see Post::Revisable). Delayed post.updated webhooks and
# fediverse Updates carry it so a superseded job can skip itself; unlike
# `updated_at`, it doesn't move on settings-only saves or counter bumps.
class AddRevisedAtToPosts < ActiveRecord::Migration[8.1]
  def up
    add_column :posts, :revised_at, :datetime
    execute "UPDATE posts SET revised_at = updated_at"
  end

  def down
    remove_column :posts, :revised_at
  end
end
