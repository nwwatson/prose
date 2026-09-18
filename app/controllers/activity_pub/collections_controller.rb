module ActivityPub
  class CollectionsController < BaseController
    OUTBOX_LIMIT = 20

    def outbox
      posts = Post.live.by_publication_date.includes(:tags, :rich_text_content, featured_image_attachment: :blob)
      render_activity collection(Urls.outbox_url, posts.count, posts.limit(OUTBOX_LIMIT).map { |post| Activities.create(post).except("@context") })
    end

    # Follower identities are not published, only the count.
    def followers
      render_activity collection(Urls.followers_url, FediverseActor.followers.count)
    end

    def following
      render_activity collection(Urls.following_url, 0)
    end

    private

    def collection(id, total, items = nil)
      {
        "@context" => Activities::CONTEXT,
        "id" => id,
        "type" => "OrderedCollection",
        "totalItems" => total,
        "orderedItems" => items
      }.compact
    end
  end
end
