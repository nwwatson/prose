module ActivityPub
  class InboxesController < BaseController
    MAX_BODY_BYTES = 256.kilobytes

    rate_limit to: 300, within: 1.minute

    def create
      body = request.raw_post.to_s
      return head :content_too_large if body.bytesize > MAX_BODY_BYTES

      activity = JSON.parse(body)
      return head :bad_request unless activity.is_a?(Hash) && activity["type"].is_a?(String)

      actor = verified_actor(activity, body)
      return if performed?

      InboxProcessor.call(activity, actor)
      head :accepted
    rescue JSON::ParserError
      head :bad_request
    end

    private

    def verified_actor(activity, body)
      actor = RequestVerifier.verify!(request, body)
      head :unauthorized unless activity_actor(activity) == actor.uri
      actor
    rescue Signature::VerificationError => e
      # A deleted account's key can no longer be fetched, so its own Delete can
      # never verify; Mastodon broadcasts these widely, so acknowledge quietly.
      if activity["type"] == "Delete" && activity["object"] == activity_actor(activity)
        head :accepted
      else
        Rails.logger.info("[ActivityPub] Rejected inbox delivery: #{e.message}")
        head :unauthorized
      end
    end

    def activity_actor(activity)
      actor = activity["actor"]
      actor.is_a?(Hash) ? actor["id"] : actor
    end
  end
end
