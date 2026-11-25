module Identity::ReadingListable
  extend ActiveSupport::Concern

  included do
    has_many :reading_list_items, dependent: :delete_all
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

    # SQLite takes the write lock when the transaction starts, so the room
    # counted here can't be taken before the insert.
    transaction do
      room = ReadingListItem::MAX_ITEMS - reading_list_items.count
      importable = Post.live.where(id: ids).where.not(id: reading_list_items.select(:post_id)).pluck(:id)
      # Ids arrive newest-first (browser order), which `&` preserves.
      insert_reading_list_items((ids & importable).first([ room, 0 ].max))
    end
  end

  private

  # One INSERT for the whole import, skipping model validations (the caller has
  # already applied them). Each row is stamped a microsecond older than the one
  # before, and inserted oldest-first, so `newest_first` returns the given order.
  def insert_reading_list_items(post_ids)
    return if post_ids.empty?

    now = Time.current
    rows = post_ids.each_with_index.map do |post_id, age|
      saved_at = now - Rational(age, 1_000_000)
      { identity_id: id, post_id: post_id, created_at: saved_at, updated_at: saved_at }
    end

    ReadingListItem.insert_all(rows.reverse, unique_by: %i[identity_id post_id])
    reading_list_items.reset
  end
end
