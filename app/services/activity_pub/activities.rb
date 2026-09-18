module ActivityPub
  # Builders for the activities this site sends.
  module Activities
    CONTEXT = "https://www.w3.org/ns/activitystreams".freeze

    module_function

    def create(post)
      wrap("Create", "#{Urls.post_url(post)}#create", ArticleSerializer.call(post, with_context: false), published: post.published_at)
    end

    # Each Update needs its own id, or receivers treat it as a duplicate.
    def update(post)
      wrap("Update", "#{Urls.post_url(post)}#update-#{post.updated_at.to_i}", ArticleSerializer.call(post, with_context: false))
    end

    def delete(object_url)
      wrap("Delete", "#{object_url}#delete-#{Time.current.to_i}", { "id" => object_url, "type" => "Tombstone" })
    end

    def accept(follow)
      {
        "@context" => CONTEXT,
        "id" => "#{Urls.actor_url}#accepts/#{SecureRandom.uuid}",
        "type" => "Accept",
        "actor" => Urls.actor_url,
        "object" => follow.slice("id", "type", "actor", "object")
      }
    end

    def wrap(type, id, object, published: nil)
      {
        "@context" => CONTEXT,
        "id" => id,
        "type" => type,
        "actor" => Urls.actor_url,
        "published" => published&.iso8601,
        "to" => [ Urls::PUBLIC_COLLECTION ],
        "cc" => [ Urls.followers_url ],
        "object" => object
      }.compact
    end
  end
end
