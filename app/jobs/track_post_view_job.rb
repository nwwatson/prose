class TrackPostViewJob < ApplicationJob
  queue_as :default

  def perform(post_id:, ip_address:, user_agent: nil, referrer: nil)
    parsed = ReferrerParser.call(referrer)

    PostView.create!(
      post_id: post_id,
      ip_hash: PostView.hash_ip(ip_address),
      user_agent: user_agent&.truncate(500),
      referrer: referrer&.truncate(2000),
      source: parsed[:source],
      referrer_domain: parsed[:domain],
      utm_source: parsed[:utm_source],
      utm_medium: parsed[:utm_medium],
      utm_campaign: parsed[:utm_campaign]
    )
  end
end
