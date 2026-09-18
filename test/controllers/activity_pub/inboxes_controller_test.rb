require "test_helper"

module ActivityPub
  class InboxesControllerTest < ActionDispatch::IntegrationTest
    include ActivityPubTestHelper

    setup do
      enable_federation!
      @actor = remote_actor
    end

    def deliver(activity, headers: nil)
      body = activity.to_json
      post activity_pub_inbox_path, params: body, headers: headers || signed_inbox_headers(body)
    end

    def follow
      { id: "https://remote.example/follows/1", type: "Follow", actor: @actor.uri, object: Urls.actor_url }
    end

    test "accepts a signed Follow" do
      deliver(follow)

      assert_response :accepted
      assert @actor.reload.follower?
    end

    test "rejects an unsigned request" do
      body = follow.to_json
      post activity_pub_inbox_path, params: body, headers: { "Content-Type" => "application/activity+json" }

      assert_response :unauthorized
      assert_not @actor.reload.follower?
    end

    test "rejects a request signed with the wrong key" do
      body = follow.to_json
      deliver(follow, headers: signed_inbox_headers(body, key: OpenSSL::PKey::RSA.new(2048)))

      assert_response :unauthorized
      assert_not @actor.reload.follower?
    end

    test "rejects activities claiming a different actor than the signer" do
      other = remote_actor(uri: "https://remote.example/users/bob", key_id: "https://remote.example/users/bob#main-key")

      deliver(follow.merge(actor: other.uri))

      assert_response :unauthorized
      assert_not other.reload.follower?
    end

    test "rejects a body modified after signing" do
      headers = signed_inbox_headers(follow.to_json)
      post activity_pub_inbox_path, params: follow.merge(object: "https://x.example").to_json, headers: headers

      assert_response :unauthorized
    end

    test "rejects malformed JSON" do
      post activity_pub_inbox_path, params: "not json", headers: signed_inbox_headers("not json")
      assert_response :bad_request
    end

    test "rejects oversized bodies" do
      body = { type: "Note", content: "a" * (InboxesController::MAX_BODY_BYTES + 1) }.to_json
      post activity_pub_inbox_path, params: body, headers: { "Content-Type" => "application/activity+json" }
      assert_response :content_too_large
    end

    test "quietly acknowledges a Delete from an actor whose key can't be fetched" do
      gone = "https://gone.example/users/zed"
      body = { type: "Delete", actor: gone, object: gone }.to_json
      failing_fetch = ->(*) { raise HttpClient::Error.new("gone", status: 410) }

      with_singleton_stub(HttpClient, :get, failing_fetch) do
        post activity_pub_inbox_path, params: body, headers: signed_inbox_headers(body, key_id: "#{gone}#main-key")
      end

      assert_response :accepted
    end
  end
end
