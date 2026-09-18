module ActivityPub
  # Route constraint: does this request want the ActivityPub representation of
  # a URL (rather than HTML), and is federation on?
  module Negotiation
    ACCEPT_PATTERN = %r{application/(activity\+json|ld\+json)}

    module_function

    def matches?(request)
      request.headers["Accept"].to_s.match?(ACCEPT_PATTERN) && SiteSetting.current.activitypub_enabled?
    end
  end
end
