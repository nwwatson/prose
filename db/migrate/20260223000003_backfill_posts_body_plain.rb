class BackfillPostsBodyPlain < ActiveRecord::Migration[8.1]
  def up
    Post.find_each do |post|
      plain_text = post.content&.to_plain_text.to_s
      post.update_column(:body_plain, plain_text)
    end

    execute "INSERT INTO posts_fts(posts_fts) VALUES ('rebuild')"
  end

  def down
    execute "INSERT INTO posts_fts(posts_fts) VALUES ('rebuild')"
    execute "UPDATE posts SET body_plain = NULL"
  end
end
