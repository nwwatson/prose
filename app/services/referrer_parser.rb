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

  # Google uses ccTLD variants (google.de, google.co.uk), so it is matched by pattern.
  GOOGLE_HOST = /(?:\A|\.)google\.(?:[a-z]{2,3}\.)?[a-z]{2,}\z/

  # Matched on whole host boundaries (exact host or a subdomain), never as a substring,
  # so `dropbox.com` or `john.example` cannot be classified as a social network.
  SOURCE_DOMAINS = {
    "twitter" => %w[x.com twitter.com t.co],
    "facebook" => %w[facebook.com fb.com],
    "linkedin" => %w[linkedin.com lnkd.in],
    "reddit" => %w[reddit.com redd.it],
    "hackernews" => %w[news.ycombinator.com]
  }.freeze

  def classify(host)
    return "google" if GOOGLE_HOST.match?(host)

    SOURCE_DOMAINS.each { |source, domains| return source if host_in?(host, domains) }

    "other"
  end

  def host_in?(host, domains)
    domains.any? { |domain| host == domain || host.end_with?(".#{domain}") }
  end
end
