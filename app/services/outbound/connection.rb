module Outbound
  # The one guarded outbound HTTP connection, shared by Webhooks::Sender and
  # ActivityPub::HttpClient. Destination URLs are attacker-controlled, so every
  # request:
  #
  # * is vetted by UrlGuard.resolve! (every DNS answer must be public), and
  #   connects to that vetted IP via Net::HTTP#ipaddr=, so a DNS rebind between
  #   the check and the connect can't redirect it to an internal address;
  # * never follows redirects (a 3xx is returned to the caller like any status);
  # * has short open/read/write timeouts;
  # * reads at most `max_bytes` of the response body.
  #
  # Callers build the Net::HTTP request and map errors and statuses.
  class Connection
    class Error < StandardError; end

    class ResponseTooLarge < Error
      attr_reader :code

      def initialize(message, code: nil)
        super(message)
        @code = code
      end
    end

    Response = Struct.new(:code, :body, :truncated)

    OPEN_TIMEOUT = 5
    READ_TIMEOUT = 10
    WRITE_TIMEOUT = 10

    # Sends `request` to `uri` and returns a Response (integer code, body).
    # When the body exceeds `max_bytes` it raises ResponseTooLarge, or with
    # `truncate: true` stops reading and returns the first `max_bytes`.
    # Raises UrlGuard::UnsafeUrlError for a disallowed host; network errors
    # propagate unchanged.
    def self.request(uri, request, max_bytes:, truncate: false)
      new(uri, max_bytes: max_bytes, truncate: truncate).request(request)
    end

    def initialize(uri, max_bytes:, truncate: false)
      raise ArgumentError, "URL must be http or https" unless uri.is_a?(URI::HTTP)

      @uri = uri
      @max_bytes = max_bytes
      @truncate = truncate
    end

    def request(request)
      code = nil
      body = +""
      truncated = false

      catch(:truncated) do
        build_http.request(request) do |response|
          code = response.code.to_i
          response.read_body do |chunk|
            body << chunk
            next if body.bytesize <= @max_bytes
            raise ResponseTooLarge.new("Response from #{@uri.host} is too large", code: code) unless @truncate

            body = body.byteslice(0, @max_bytes)
            truncated = true
            # Leaving the block closes the connection without reading the rest.
            throw :truncated
          end
        end
      end

      Response.new(code, body, truncated)
    end

    private

    def build_http
      http = Net::HTTP.new(@uri.hostname, @uri.port)
      http.ipaddr = UrlGuard.resolve!(@uri.hostname)
      http.use_ssl = @uri.scheme == "https"
      http.open_timeout = OPEN_TIMEOUT
      http.read_timeout = READ_TIMEOUT
      http.write_timeout = WRITE_TIMEOUT
      http
    end
  end
end
