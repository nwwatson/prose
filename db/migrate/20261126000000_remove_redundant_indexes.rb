# Each of these single-column indexes is a left prefix of a composite index on
# the same table, so it costs a write on every insert and serves no query the
# composite can't.
class RemoveRedundantIndexes < ActiveRecord::Migration[8.1]
  def change
    remove_index :post_views, column: :post_id, name: "index_post_views_on_post_id"
    remove_index :posts, column: :status, name: "index_posts_on_status"
    remove_index :post_tags, column: :post_id, name: "index_post_tags_on_post_id"
    remove_index :loves, column: :post_id, name: "index_loves_on_post_id"
    remove_index :newsletter_deliveries, column: :newsletter_id, name: "index_newsletter_deliveries_on_newsletter_id"
    remove_index :subscriber_labelings, column: :subscriber_id, name: "index_subscriber_labelings_on_subscriber_id"
    remove_index :post_versions, column: :post_id, name: "index_post_versions_on_post_id"
    remove_index :webhook_deliveries, column: :webhook_id, name: "index_webhook_deliveries_on_webhook_id"
    remove_index :fediverse_likes, column: :post_id, name: "index_fediverse_likes_on_post_id"
    remove_index :chats, column: :post_id, name: "index_chats_on_post_id"
  end
end
