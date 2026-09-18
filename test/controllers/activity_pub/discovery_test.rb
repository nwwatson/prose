require "test_helper"

module ActivityPub
  class DiscoveryTest < ActionDispatch::IntegrationTest
    include ActivityPubTestHelper

    ACCEPT = { "Accept" => "application/activity+json" }.freeze

    test "every endpoint 404s while federation is disabled" do
      get webfinger_path(resource: "acct:blog@example.com")
      assert_response :not_found
      get activity_pub_actor_path
      assert_response :not_found
      get activity_pub_outbox_path
      assert_response :not_found
      post activity_pub_inbox_path, params: "{}", headers: { "Content-Type" => "application/activity+json" }
      assert_response :not_found
    end

    test "post URLs still serve HTML to ActivityPub clients while disabled" do
      get post_path(slug: posts(:published_post).slug), headers: ACCEPT
      assert_response :success
      assert_match "text/html", response.media_type
    end

    test "webfinger resolves the site handle to the actor" do
      enable_federation!(activitypub_username: "journal")

      get webfinger_path(resource: "acct:journal@#{Urls.host}")

      assert_response :success
      assert_equal "application/jrd+json", response.media_type
      json = JSON.parse(response.body)
      assert_equal "acct:journal@#{Urls.host}", json["subject"]
      assert_equal Urls.actor_url, json["links"].find { |link| link["rel"] == "self" }["href"]
    end

    test "webfinger 404s for other users" do
      enable_federation!
      get webfinger_path(resource: "acct:someone@#{Urls.host}")
      assert_response :not_found
    end

    test "actor document exposes the public key and endpoints" do
      enable_federation!

      get activity_pub_actor_path

      assert_response :success
      assert_equal "application/activity+json", response.media_type
      json = JSON.parse(response.body)
      assert_equal "Person", json["type"]
      assert_equal "blog", json["preferredUsername"]
      assert_equal Urls.inbox_url, json["inbox"]
      assert_equal Urls.key_id, json.dig("publicKey", "id")
      assert_equal SiteSetting.current.activitypub_public_key, json.dig("publicKey", "publicKeyPem")
      assert_no_match(/PRIVATE/, response.body)
    end

    test "outbox lists Create activities for live posts only" do
      enable_federation!

      get activity_pub_outbox_path

      json = JSON.parse(response.body)
      assert_equal Post.live.count, json["totalItems"]
      ids = json["orderedItems"].map { |item| item.dig("object", "id") }
      assert_includes ids, Urls.post_url(posts(:published_post))
      assert_not_includes ids, Urls.post_url(posts(:draft_post))
    end

    test "followers collection publishes only a count" do
      enable_federation!
      remote_actor.follow!

      get activity_pub_followers_path

      json = JSON.parse(response.body)
      assert_equal 1, json["totalItems"]
      assert_nil json["orderedItems"]
    end

    test "post URLs serve the Article to ActivityPub clients" do
      enable_federation!
      post = posts(:published_post)

      get post_path(slug: post.slug), headers: ACCEPT

      assert_response :success
      assert_equal "application/activity+json", response.media_type
      assert_equal Urls.post_url(post), JSON.parse(response.body)["id"]
    end

    test "draft posts are not served as ActivityPub objects" do
      enable_federation!
      get post_path(slug: posts(:draft_post).slug), headers: ACCEPT
      assert_response :not_found
    end

    test "browsers still get HTML with an alternate link to the ActivityPub object" do
      enable_federation!
      post = posts(:published_post)

      get post_path(slug: post.slug)

      assert_response :success
      assert_select "link[rel=alternate][type='application/activity+json'][href=?]", Urls.post_url(post)
    end
  end
end
