module ActivityPubTestHelper
  include ActiveJob::TestHelper

  REMOTE_ACTOR_URI = "https://remote.example/users/alice".freeze
  REMOTE_KEY_ID = "#{REMOTE_ACTOR_URI}#main-key".freeze

  # The remote test actor's keypair, generated on first use (per worker) rather
  # than when the test helper loads, so runs without ActivityPub tests skip it.
  def self.remote_key
    @remote_key ||= OpenSSL::PKey::RSA.new(2048)
  end

  def remote_key
    ActivityPubTestHelper.remote_key
  end

  def enable_federation!(**attrs)
    SiteSetting.current.update!(activitypub_enabled: true, **attrs)
  end

  def remote_actor(**attrs)
    FediverseActor.create!({
      uri: REMOTE_ACTOR_URI,
      inbox_url: "#{REMOTE_ACTOR_URI}/inbox",
      shared_inbox_url: "https://remote.example/inbox",
      key_id: REMOTE_KEY_ID,
      public_key_pem: remote_key.public_to_pem,
      username: "alice",
      name: "Alice",
      profile_url: "https://remote.example/@alice",
      fetched_at: Time.current
    }.merge(attrs))
  end

  # Headers for a request signed by the remote test actor, as Mastodon sends them.
  def signed_inbox_headers(body, key: remote_key, key_id: REMOTE_KEY_ID, path: "/activitypub/inbox")
    ActivityPub::Signature.sign(method: :post, url: "http://www.example.com#{path}", key: key, key_id: key_id, body: body)
      .merge("Content-Type" => "application/activity+json")
  end
end
