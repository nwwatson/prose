require "test_helper"

module ActivityPub
  class InboxProcessorTest < ActiveSupport::TestCase
    include ActivityPubTestHelper

    setup do
      enable_federation!
      @actor = remote_actor
      @post = posts(:published_post)
    end

    def process(activity)
      InboxProcessor.call(activity.deep_stringify_keys, @actor)
    end

    def note(**attrs)
      {
        id: "https://remote.example/users/alice/statuses/1",
        type: "Note",
        attributedTo: @actor.uri,
        inReplyTo: Urls.post_url(@post),
        content: "<p>Lovely post</p>",
        to: [ Urls::PUBLIC_COLLECTION ]
      }.merge(attrs)
    end

    def create_note(**attrs)
      { id: "https://remote.example/activities/1", type: "Create", actor: @actor.uri, object: note(**attrs) }
    end

    test "Follow makes the actor a follower and sends an Accept" do
      follow = { id: "https://remote.example/follows/1", type: "Follow", actor: @actor.uri, object: Urls.actor_url }

      assert_enqueued_with(job: DeliverActivityJob) { process(follow) }
      assert @actor.reload.follower?

      accept = JSON.parse(enqueued_jobs.last[:args].last)
      assert_equal "Accept", accept["type"]
      assert_equal "https://remote.example/follows/1", accept.dig("object", "id")
      assert_equal @actor.inbox_url, enqueued_jobs.last[:args].first
    end

    test "Follow of some other object is ignored" do
      assert_no_enqueued_jobs { process(type: "Follow", actor: @actor.uri, object: "https://elsewhere.example/actor") }
      assert_not @actor.reload.follower?
    end

    test "Undo Follow removes the follower" do
      @actor.follow!
      process(type: "Undo", actor: @actor.uri, object: { type: "Follow", actor: @actor.uri, object: Urls.actor_url })
      assert_not @actor.reload.follower?
    end

    test "Like records one like per actor and post, and Undo removes it" do
      like = { id: "https://remote.example/likes/1", type: "Like", actor: @actor.uri, object: Urls.post_url(@post) }

      assert_difference -> { @post.fediverse_likes.count }, 1 do
        process(like)
        process(like)
      end

      assert_difference -> { @post.fediverse_likes.count }, -1 do
        process(type: "Undo", actor: @actor.uri, object: like)
      end
    end

    test "Like of an unknown object is ignored" do
      assert_no_difference -> { FediverseLike.count } do
        process(type: "Like", actor: @actor.uri, object: "https://example.com/posts/does-not-exist")
      end
    end

    test "Like of a draft post is ignored" do
      assert_no_difference -> { FediverseLike.count } do
        process(type: "Like", actor: @actor.uri, object: Urls.post_url(posts(:draft_post)))
      end
    end

    test "a public reply becomes a comment held for moderation" do
      assert_difference -> { @post.comments.count }, 1 do
        process(create_note)
      end

      comment = @post.comments.order(:id).last
      assert_not comment.approved?
      assert comment.federated?
      assert_equal "Lovely post", comment.body
      assert_equal "Alice", comment.identity.name
      assert_equal comment.identity, @actor.reload.identity
    end

    test "duplicate deliveries create only one comment" do
      assert_difference -> { Comment.count }, 1 do
        process(create_note)
        process(create_note)
      end
    end

    test "replies to a fediverse comment are threaded under it" do
      process(create_note)
      parent = Comment.find_by!(activitypub_uri: note[:id])

      process(create_note(id: "https://remote.example/users/alice/statuses/2", inReplyTo: note[:id]))
      reply = Comment.find_by!(activitypub_uri: "https://remote.example/users/alice/statuses/2")
      assert_equal parent, reply.parent_comment
      assert_equal @post, reply.post
    end

    test "direct messages are not turned into comments" do
      assert_no_difference -> { Comment.count } do
        process(create_note(to: [ Urls.actor_url ]))
      end
    end

    test "notes attributed to someone else are ignored" do
      assert_no_difference -> { Comment.count } do
        process(create_note(attributedTo: "https://remote.example/users/mallory"))
      end
    end

    test "notes hosted on another domain are ignored" do
      assert_no_difference -> { Comment.count } do
        process(create_note(id: "https://evil.example/statuses/1"))
      end
    end

    test "replies to something other than our posts are ignored" do
      assert_no_difference -> { Comment.count } do
        process(create_note(inReplyTo: "https://remote.example/statuses/99"))
      end
    end

    test "Delete soft-deletes the actor's own comment" do
      process(create_note)
      process(type: "Delete", actor: @actor.uri, object: { id: note[:id], type: "Tombstone" })

      assert Comment.find_by!(activitypub_uri: note[:id]).deleted?
    end

    test "Delete cannot remove another identity's comment" do
      comment = comments(:top_level)
      comment.update_columns(activitypub_uri: "https://remote.example/statuses/theirs")
      @actor.ensure_identity!

      process(type: "Delete", actor: @actor.uri, object: "https://remote.example/statuses/theirs")
      assert_not comment.reload.deleted?
    end

    test "Delete of the actor itself removes its follow and likes" do
      @actor.follow!
      @post.fediverse_likes.create!(fediverse_actor: @actor)

      process(type: "Delete", actor: @actor.uri, object: @actor.uri)

      assert_not @actor.reload.follower?
      assert_empty @actor.fediverse_likes
    end

    test "unknown activity types are ignored" do
      assert_nil process(type: "Announce", actor: @actor.uri, object: Urls.post_url(@post))
    end
  end
end
