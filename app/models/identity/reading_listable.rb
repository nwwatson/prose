module Identity::ReadingListable
  extend ActiveSupport::Concern

  included do
    has_many :reading_list_items, dependent: :destroy
  end

  # Live posts only, most recently saved first.
  def reading_list_posts
    Post.live.for_listing
      .joins(:reading_list_items)
      .merge(reading_list_items.newest_first)
  end

  # Ids of live saved posts, newest first — what the bookmark buttons key off.
  def reading_list_post_ids
    reading_list_items.joins(:post).merge(Post.live).newest_first.pluck(:post_id)
  end

  def bookmark!(post)
    reading_list_items.find_or_create_by!(post: post)
  end

  # Accepts a Post or a post id, so a reader can remove a post that's since been unpublished.
  def unbookmark!(post)
    reading_list_items.where(post: post).destroy_all
  end

  # Merges posts saved in the browser (before signing in) into this identity's
  # list. Unknown, unpublished, and already-saved ids are skipped silently, and
  # the import stops at ReadingListItem::MAX_ITEMS.
  def import_reading_list!(post_ids)
    ids = Array(post_ids).map(&:to_i).select(&:positive?).uniq
    return if ids.empty?

    room = ReadingListItem::MAX_ITEMS - reading_list_items.count
    new_ids = Post.live.where(id: ids).where.not(id: reading_list_items.select(:post_id)).pluck(:id)
    # Ids arrive newest-first (browser order); keep the newest that fit, then
    # insert oldest-first so created_at preserves the reader's ordering.
    new_ids = new_ids.sort_by { |id| ids.index(id) }.first([ room, 0 ].max)

    transaction do
      new_ids.reverse_each { |id| reading_list_items.create!(post_id: id) }
    end
  end
end
