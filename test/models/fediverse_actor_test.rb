require "test_helper"

class FediverseActorTest < ActiveSupport::TestCase
  include ActivityPubTestHelper

  test "follower_inboxes prefers shared inboxes and deduplicates them" do
    remote_actor.follow!
    remote_actor(uri: "https://remote.example/users/bob", key_id: "bob#key").follow!
    remote_actor(uri: "https://solo.example/users/carol", key_id: "carol#key", shared_inbox_url: nil, inbox_url: "https://solo.example/users/carol/inbox").follow!
    remote_actor(uri: "https://quiet.example/users/dan", key_id: "dan#key")

    assert_equal [ "https://remote.example/inbox", "https://solo.example/users/carol/inbox" ].sort, FediverseActor.follower_inboxes.sort
  end

  test "unfollow_inbox! drops every follower delivered through that inbox" do
    alice = remote_actor.tap(&:follow!)
    bob = remote_actor(uri: "https://remote.example/users/bob", key_id: "bob#key").tap(&:follow!)

    FediverseActor.unfollow_inbox!("https://remote.example/inbox")

    assert_not alice.reload.follower?
    assert_not bob.reload.follower?
  end

  test "handle and display name" do
    actor = remote_actor
    assert_equal "@alice@remote.example", actor.handle
    assert_equal "Alice", actor.display_name
    assert_equal "bob", remote_actor(uri: "https://remote.example/u/bob", key_id: "bob", name: nil, username: "bob").display_name
  end

  test "ensure_identity! creates one identity for the actor" do
    actor = remote_actor

    identity = actor.ensure_identity!

    assert_equal "Alice", identity.name
    assert_equal "https://remote.example/@alice", identity.website_url
    assert_nil identity.handle
    assert_no_difference(-> { Identity.count }) { actor.ensure_identity! }
  end

  test "stale? after a day" do
    assert_not remote_actor.stale?
    assert remote_actor(uri: "https://remote.example/u/old", key_id: "old", fetched_at: 2.days.ago).stale?
  end
end
