module ActivityPub
  # The site's single actor document — what a Mastodon user sees when they
  # look up @username@host.
  module ActorSerializer
    CONTEXT = [ "https://www.w3.org/ns/activitystreams", "https://w3id.org/security/v1" ].freeze

    module_function

    def call(site = SiteSetting.current)
      {
        "@context" => CONTEXT,
        "id" => Urls.actor_url,
        "type" => "Person",
        "preferredUsername" => site.activitypub_username,
        "name" => site.site_name,
        "summary" => ERB::Util.html_escape(site.site_description.to_s),
        "url" => Urls.base_url,
        "inbox" => Urls.inbox_url,
        "outbox" => Urls.outbox_url,
        "followers" => Urls.followers_url,
        "following" => Urls.following_url,
        "endpoints" => { "sharedInbox" => Urls.inbox_url },
        "manuallyApprovesFollowers" => false,
        "discoverable" => true,
        "publicKey" => {
          "id" => Urls.key_id,
          "owner" => Urls.actor_url,
          "publicKeyPem" => site.activitypub_public_key
        },
        "icon" => icon(site)
      }.compact
    end

    def icon(site)
      return unless site.default_og_image.attached?

      { "type" => "Image", "mediaType" => site.default_og_image.content_type, "url" => Urls.blob_url(site.default_og_image) }
    end
  end
end
