module ActivityPub
  # Fetches and caches remote actor documents as FediverseActor rows.
  module ActorFetcher
    ACTOR_TYPES = %w[Person Service Application Group Organization].freeze

    module_function

    def fetch(uri, refresh: false)
      actor = FediverseActor.find_by(uri: uri)
      return actor if actor && !refresh && !actor.stale?

      document = HttpClient.get(uri)
      raise HttpClient::Error, "#{uri} is not an ActivityPub actor" unless ACTOR_TYPES.include?(document["type"])
      # The document must describe the URI we asked for; otherwise one server
      # could hand us a key for an actor it doesn't host.
      raise HttpClient::Error, "Actor id does not match #{uri}" unless document["id"] == uri

      actor ||= FediverseActor.new(uri: uri)
      actor.update!(attributes_from(document))
      actor
    rescue ActiveRecord::RecordNotUnique
      FediverseActor.find_by!(uri: uri)
    end

    # Resolves the actor that owns a signature keyId (usually "<actor>#main-key").
    def for_key_id(key_id, refresh: false)
      unless refresh
        cached = FediverseActor.find_by(key_id: key_id)
        return cached if cached && !cached.stale?
      end

      fetch(key_id.to_s.split("#").first, refresh: true).tap do |actor|
        raise HttpClient::Error, "Key #{key_id} does not belong to #{actor.uri}" unless actor.key_id == key_id
      end
    end

    def attributes_from(document)
      public_key = document["publicKey"].is_a?(Array) ? document["publicKey"].first : document["publicKey"]
      public_key = {} unless public_key.is_a?(Hash) && public_key["owner"] == document["id"]

      {
        inbox_url: document["inbox"],
        shared_inbox_url: document.dig("endpoints", "sharedInbox"),
        key_id: public_key["id"],
        public_key_pem: public_key["publicKeyPem"],
        username: document["preferredUsername"],
        name: document["name"].presence&.then { |name| ActionController::Base.helpers.strip_tags(name) },
        profile_url: document["url"].is_a?(String) ? document["url"] : document["id"],
        fetched_at: Time.current
      }
    end
  end
end
