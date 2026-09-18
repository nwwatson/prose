module ActivityPub
  # Signed server-to-server HTTP for federation. Every request goes through
  # Webhooks::UrlGuard (remote actor and inbox URLs are attacker-controlled, so
  # this is an SSRF surface) and connects to the vetted IP. Redirects are not
  # followed, and response bodies are capped.
  class HttpClient
    class Error < StandardError
      attr_reader :status

      def initialize(message, status: nil)
        super(message)
        @status = status
      end
    end

    ACCEPT = %(application/activity+json, application/ld+json; profile="https://www.w3.org/ns/activitystreams").freeze
    CONTENT_TYPE = "application/activity+json".freeze
    MAX_RESPONSE_BYTES = 1.megabyte
    OPEN_TIMEOUT = 5
    READ_TIMEOUT = 10
    WRITE_TIMEOUT = 10

    def self.get(url)
      new.get(url)
    end

    def self.post(url, body)
      new.post(url, body)
    end

    def get(url)
      body = perform(:get, url)
      JSON.parse(body)
    rescue JSON::ParserError
      raise Error, "Response from #{url} is not JSON"
    end

    def post(url, body)
      perform(:post, url, body)
    end

    private

    def perform(method, url, body = nil)
      uri = URI(url)
      raise Error, "URL must be https" unless uri.is_a?(URI::HTTPS) || (uri.is_a?(URI::HTTP) && !Rails.env.production?)

      http = Net::HTTP.new(uri.hostname, uri.port)
      http.ipaddr = Webhooks::UrlGuard.resolve!(uri.hostname)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = OPEN_TIMEOUT
      http.read_timeout = READ_TIMEOUT
      http.write_timeout = WRITE_TIMEOUT

      response_body = +""
      status = nil
      http.request(build_request(method, uri, body)) do |response|
        status = response.code.to_i
        response.read_body do |chunk|
          response_body << chunk
          raise Error, "Response from #{url} is too large" if response_body.bytesize > MAX_RESPONSE_BYTES
        end
      end

      raise Error.new("#{url} returned #{status}", status: status) unless status.between?(200, 299)

      response_body
    rescue Error
      raise
    rescue Webhooks::UrlGuard::UnsafeUrlError, URI::InvalidURIError, ArgumentError => e
      raise Error, e.message
    rescue StandardError => e
      raise Error, "#{e.class}: #{e.message}"
    end

    def build_request(method, uri, body)
      request = method == :post ? Net::HTTP::Post.new(uri.request_uri) : Net::HTTP::Get.new(uri.request_uri)
      request["Accept"] = ACCEPT
      request["User-Agent"] = "Prose (+#{Urls.base_url})"
      if body
        request["Content-Type"] = CONTENT_TYPE
        request.body = body
      end

      # Signed GETs let us fetch actors from servers running "authorized fetch".
      key = SiteSetting.current.activitypub_signing_key
      if key
        Signature.sign(method: method, url: uri.to_s, key: key, key_id: Urls.key_id, body: body).each do |name, value|
          request[name] = value
        end
      end
      request
    end
  end
end
