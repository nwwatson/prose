module Post::Discoverable
  extend ActiveSupport::Concern

  def related_posts(limit: 3)
    candidates = tag_matched_posts(limit)
    candidates = backfill_with_category(candidates, limit) if candidates.size < limit
    candidates = backfill_with_recent(candidates, limit) if candidates.size < limit
    candidates
  end

  def previous_post
    Post.live.where("published_at < ?", published_at).order(published_at: :desc).first
  end

  def next_post
    Post.live.where("published_at > ?", published_at).order(published_at: :asc).first
  end

  private

  def tag_matched_posts(limit)
    return Post.none.to_a if tag_ids.empty?

    Post.live
        .where.not(id: id)
        .joins(:tags)
        .where(tags: { id: tag_ids })
        .group("posts.id")
        .order(Arel.sql("COUNT(tags.id) DESC, posts.published_at DESC"))
        .limit(limit)
        .to_a
  end

  def backfill_with_category(candidates, limit)
    return candidates if category_id.blank?

    exclude_ids = [ id ] + candidates.map(&:id)
    remaining = limit - candidates.size

    category_posts = Post.live
                         .where(category_id: category_id)
                         .where.not(id: exclude_ids)
                         .order(published_at: :desc)
                         .limit(remaining)
                         .to_a

    candidates + category_posts
  end

  def backfill_with_recent(candidates, limit)
    exclude_ids = [ id ] + candidates.map(&:id)
    remaining = limit - candidates.size

    recent_posts = Post.live
                       .where.not(id: exclude_ids)
                       .order(published_at: :desc)
                       .limit(remaining)
                       .to_a

    candidates + recent_posts
  end
end
