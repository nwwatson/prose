class DeliverActivityJob < ApplicationJob
  MAX_ATTEMPTS = 5

  queue_as :default

  # Once retries are exhausted the delivery is dropped; the remote server will
  # simply miss this activity.
  retry_on ActivityPub::HttpClient::Error, wait: :polynomially_longer, attempts: MAX_ATTEMPTS do |job, error|
    Rails.logger.warn("[ActivityPub] Giving up delivering to #{job.arguments.first}: #{error.message}")
  end

  def perform(inbox_url, body)
    return unless SiteSetting.current.activitypub_enabled?

    ActivityPub::HttpClient.post(inbox_url, body)
  rescue ActivityPub::HttpClient::Error => e
    case e.status
    when 410
      # The inbox is gone for good — stop delivering to its followers.
      FediverseActor.unfollow_inbox!(inbox_url)
    when 400..499
      # Other client errors won't succeed on retry (except rate limiting).
      raise if e.status == 429

      Rails.logger.warn("[ActivityPub] #{inbox_url} rejected delivery: #{e.message}")
    else
      raise
    end
  end
end
