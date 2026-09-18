require "test_helper"

module ActivityPub
  class ActorFetcherTest < ActiveSupport::TestCase
    include ActivityPubTestHelper

    def actor_document(**overrides)
      {
        "id" => REMOTE_ACTOR_URI,
        "type" => "Person",
        "preferredUsername" => "alice",
        "name" => "<b>Alice</b>",
        "url" => "https://remote.example/@alice",
        "inbox" => "#{REMOTE_ACTOR_URI}/inbox",
        "endpoints" => { "sharedInbox" => "https://remote.example/inbox" },
        "publicKey" => { "id" => REMOTE_KEY_ID, "owner" => REMOTE_ACTOR_URI, "publicKeyPem" => REMOTE_KEY.public_to_pem }
      }.merge(overrides)
    end

    def with_document(document, &block)
      requested = []
      with_singleton_stub(HttpClient, :get, ->(url) { requested << url; document }) { block.call(requested) }
    end

    test "fetches and caches an actor" do
      with_document(actor_document) do |requested|
        actor = ActorFetcher.for_key_id(REMOTE_KEY_ID)

        assert_equal REMOTE_ACTOR_URI, actor.uri
        assert_equal "https://remote.example/inbox", actor.shared_inbox_url
        assert_equal REMOTE_KEY.public_to_pem, actor.public_key_pem
        assert_equal "Alice", actor.name
        assert_equal [ REMOTE_ACTOR_URI ], requested

        ActorFetcher.for_key_id(REMOTE_KEY_ID)
        assert_equal 1, requested.size, "a fresh cached actor is not refetched"
      end
    end

    test "rejects a document whose id doesn't match the requested URI" do
      with_document(actor_document("id" => "https://evil.example/users/alice")) do
        assert_raises(HttpClient::Error) { ActorFetcher.fetch(REMOTE_ACTOR_URI) }
      end
    end

    test "rejects non-actor documents" do
      with_document(actor_document("type" => "Note")) do
        assert_raises(HttpClient::Error) { ActorFetcher.fetch(REMOTE_ACTOR_URI) }
      end
    end

    test "ignores a public key owned by someone else" do
      key = { "id" => REMOTE_KEY_ID, "owner" => "https://evil.example/actor", "publicKeyPem" => REMOTE_KEY.public_to_pem }
      with_document(actor_document("publicKey" => key)) do
        assert_raises(HttpClient::Error) { ActorFetcher.for_key_id(REMOTE_KEY_ID) }
      end
    end
  end
end
