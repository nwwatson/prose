class TrackPostViewJob < ApplicationJob
  queue_as :default

  def perform(post_id:, ip_address:, user_agent: nil, referrer: nil)
    PostView.create!(
      post_id: post_id,
      ip_hash: PostView.hash_ip(ip_address),
      user_agent: user_agent&.truncate(500),
      referrer: referrer&.truncate(2000),
      source: extract_source(referrer)
    )
  end

  private

  def extract_source(referrer)
    return "direct" if referrer.blank?

    host = URI.parse(referrer).host.to_s.downcase
    case host
    when /google/ then "google"
    when /twitter|x\.com/ then "twitter"
    when /facebook/ then "facebook"
    when /linkedin/ then "linkedin"
    when /reddit/ then "reddit"
    when /hn|hacker-news|news\.ycombinator/ then "hackernews"
    else "other"
    end
  rescue URI::InvalidURIError
    "other"
  end
end
