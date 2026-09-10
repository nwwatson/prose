class ReferrerParser
  DIRECT_RESULT = { source: "direct", domain: nil, utm_source: nil, utm_medium: nil, utm_campaign: nil }.freeze

  def self.call(referrer)
    new(referrer).call
  end

  def initialize(referrer)
    @referrer = referrer
  end

  def call
    return DIRECT_RESULT.dup if @referrer.blank?

    uri = URI.parse(@referrer)
    host = uri.host.to_s.downcase
    domain = host.sub(/\Awww\./, "").truncate(255) if host.present?

    result = { source: classify(host), domain: domain, utm_source: nil, utm_medium: nil, utm_campaign: nil }

    if uri.query.present?
      params = URI.decode_www_form(uri.query).to_h
      result[:utm_source] = params["utm_source"]&.truncate(255)
      result[:utm_medium] = params["utm_medium"]&.truncate(255)
      result[:utm_campaign] = params["utm_campaign"]&.truncate(255)
    end

    result
  rescue URI::InvalidURIError
    { source: "other", domain: nil, utm_source: nil, utm_medium: nil, utm_campaign: nil }
  end

  private

  def classify(host)
    case host
    when /google/ then "google"
    when /twitter|x\.com/ then "twitter"
    when /facebook/ then "facebook"
    when /linkedin/ then "linkedin"
    when /reddit/ then "reddit"
    when /hn|hacker-news|news\.ycombinator/ then "hackernews"
    else "other"
    end
  end
end
