class TrackPostViewJob < ApplicationJob
  queue_as :default

  def perform(post_id:, ip_address:, user_agent: nil, referrer: nil)
    parsed = parse_referrer(referrer)

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

  private

  def parse_referrer(referrer)
    result = { source: "direct", domain: nil, utm_source: nil, utm_medium: nil, utm_campaign: nil }
    return result if referrer.blank?

    uri = URI.parse(referrer)
    host = uri.host.to_s.downcase
    result[:domain] = host.sub(/\Awww\./, "").truncate(255) if host.present?

    result[:source] = case host
    when /google/ then "google"
    when /twitter|x\.com/ then "twitter"
    when /facebook/ then "facebook"
    when /linkedin/ then "linkedin"
    when /reddit/ then "reddit"
    when /hn|hacker-news|news\.ycombinator/ then "hackernews"
    else "other"
    end

    if uri.query.present?
      params = URI.decode_www_form(uri.query).to_h
      result[:utm_source] = params["utm_source"]&.truncate(255)
      result[:utm_medium] = params["utm_medium"]&.truncate(255)
      result[:utm_campaign] = params["utm_campaign"]&.truncate(255)
    end

    result
  rescue URI::InvalidURIError
    result[:source] = "other"
    result
  end
end
