class OembedFetcher
  # This runs synchronously inside an admin request (pasting an embed), so a
  # stalled provider must give up quickly rather than pin a Puma thread for
  # Net::HTTP's 60-second defaults.
  OPEN_TIMEOUT = 5
  READ_TIMEOUT = 10

  def self.fetch(endpoint_url)
    new(endpoint_url).fetch
  end

  def initialize(endpoint_url)
    @endpoint_url = endpoint_url
  end

  def fetch
    uri = URI(@endpoint_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = OPEN_TIMEOUT
    http.read_timeout = READ_TIMEOUT
    # Some system OpenSSL builds default to non-zero verification flags that
    # reject valid oEmbed provider certs; reset to the standard flags.
    http.cert_store = OpenSSL::X509::Store.new.tap { |store| store.set_default_paths; store.flags = 0 }
    response = http.get(uri.request_uri)
    JSON.parse(response.body)
  rescue StandardError => e
    Rails.logger.warn("OembedFetcher fetch failed for #{@endpoint_url}: #{e.message}")
    {}
  end
end
