module ActivityPub
  # Authenticates an inbox request: resolves the signing actor from the
  # signature's keyId and verifies the signature against its public key.
  # Returns the verified FediverseActor.
  module RequestVerifier
    module_function

    def verify!(request, body)
      verifier = Signature::Verifier.new(method: request.request_method, path: request.fullpath, headers: request.headers, body: body)
      actor = ActorFetcher.for_key_id(verifier.key_id)

      begin
        verifier.verify!(actor.public_key_pem)
      rescue Signature::VerificationError
        # The actor may have rotated its key since we cached it; refetch once.
        raise if actor.fetched_at && actor.fetched_at > 1.minute.ago

        actor = ActorFetcher.for_key_id(verifier.key_id, refresh: true)
        verifier.verify!(actor.public_key_pem)
      end

      actor
    rescue HttpClient::Error => e
      raise Signature::VerificationError, "Could not fetch signing actor: #{e.message}"
    end
  end
end
