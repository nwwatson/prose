module ActivityPub
  # Applies an activity delivered to our inbox. `actor` is the FediverseActor
  # whose HTTP signature was verified, and the activity's own "actor" has
  # already been checked to match it — so every handler can trust that the
  # activity came from `actor`, but nothing else about the payload.
  class InboxProcessor
    HANDLED_TYPES = %w[Follow Undo Like Create Delete].freeze

    def self.call(activity, actor)
      new(activity, actor).call
    end

    def initialize(activity, actor)
      @activity = activity
      @actor = actor
    end

    def call
      type = @activity["type"]
      send(:"handle_#{type.underscore}", @activity) if HANDLED_TYPES.include?(type)
    end

    private

    def handle_follow(activity)
      return unless target_id(activity) == Urls.actor_url

      @actor.follow!
      DeliverActivityJob.perform_later(@actor.inbox_url, Activities.accept(activity).to_json) if @actor.inbox_url.present?
    end

    def handle_undo(activity)
      inner = activity["object"]

      if inner.is_a?(Hash)
        return unless inner["actor"].nil? || inner["actor"] == @actor.uri

        case inner["type"]
        when "Follow" then @actor.unfollow! if target_id(inner) == Urls.actor_url
        when "Like" then undo_like(inner)
        end
      elsif inner.is_a?(String)
        @actor.fediverse_likes.where(activity_uri: inner).destroy_all
      end
    end

    def handle_like(activity)
      post = Urls.post_for(target_id(activity))
      return unless post

      post.fediverse_likes.find_or_create_by!(fediverse_actor: @actor) { |like| like.activity_uri = activity["id"] }
    rescue ActiveRecord::RecordNotUnique
      nil
    end

    def undo_like(like)
      post = Urls.post_for(target_id(like))
      scope = @actor.fediverse_likes
      scope = post ? scope.where(post: post) : scope.where(activity_uri: like["id"])
      scope.destroy_all
    end

    def handle_create(activity)
      note = activity["object"]
      return unless note.is_a?(Hash) && note["type"] == "Note"
      return unless note["attributedTo"] == @actor.uri && same_origin?(note["id"])
      return unless public?(note) || public?(activity)
      return if Comment.exists?(activitypub_uri: note["id"])

      post, parent = reply_target(note["inReplyTo"])
      return unless post

      body = CommentBody.from_html(note["content"])
      return if body.blank?

      # Held for moderation: fediverse replies appear under /admin/comments
      # before they're shown publicly.
      post.comments.create!(
        identity: @actor.ensure_identity!,
        parent_comment: parent,
        body: body,
        approved: false,
        activitypub_uri: note["id"]
      )
    rescue ActiveRecord::RecordNotUnique
      nil
    end

    def handle_delete(activity)
      target = target_id(activity)
      return if target.blank?

      if target == @actor.uri
        @actor.unfollow!
        @actor.fediverse_likes.destroy_all
      elsif @actor.identity
        comment = Comment.find_by(activitypub_uri: target, identity: @actor.identity)
        comment&.soft_delete! unless comment&.deleted?
      end
    end

    # Replies may target a post, or a top-level fediverse comment on a post
    # (comments are one level deep, so replies to replies are dropped).
    def reply_target(in_reply_to)
      in_reply_to = target_id("object" => in_reply_to)
      return if in_reply_to.blank?

      if (post = Urls.post_for(in_reply_to))
        [ post, nil ]
      elsif (parent = Comment.top_level.visible.find_by(activitypub_uri: in_reply_to)) && parent.post.published?
        [ parent.post, parent ]
      end
    end

    def target_id(activity)
      object = activity["object"]
      object.is_a?(Hash) ? object["id"] : object
    end

    def public?(object)
      Array(object["to"]).concat(Array(object["cc"])).any? { |recipient| [ Urls::PUBLIC_COLLECTION, "as:Public", "Public" ].include?(recipient) }
    end

    def same_origin?(uri)
      URI.parse(uri.to_s).host.present? && URI.parse(uri.to_s).host == @actor.domain
    rescue URI::InvalidURIError
      false
    end
  end
end
