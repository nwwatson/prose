module Post::Discoverable
  extend ActiveSupport::Concern

  def related_posts(limit: 3)
    candidates = tag_matched_posts(limit)
    candidates = backfill(candidates, limit, Post.live.where(category_id: category_id)) if candidates.size < limit && category_id.present?
    candidates = backfill(candidates, limit, Post.live) if candidates.size < limit
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
        .with_attached_featured_image
        .group("posts.id")
        .order(Arel.sql("COUNT(tags.id) DESC"), published_at: :desc)
        .limit(limit)
        .to_a
  end

  # Tops `candidates` up to `limit` with the newest posts in `scope`.
  def backfill(candidates, limit, scope)
    exclude_ids = [ id ] + candidates.map(&:id)

    candidates + scope.where.not(id: exclude_ids)
                      .with_attached_featured_image
                      .order(published_at: :desc)
                      .limit(limit - candidates.size)
                      .to_a
  end
end
