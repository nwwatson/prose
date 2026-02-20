class AddSourcePostToSubscribers < ActiveRecord::Migration[8.1]
  def change
    add_reference :subscribers, :source_post, null: true, foreign_key: { to_table: :posts }
  end
end
