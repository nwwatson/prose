module Webhooks
  class Sender
    class DeliveryError < StandardError
      attr_reader :response_code

      def initialize(message, response_code: nil)
        super(message)
        @response_code = response_code
      end
    end

    Response = Struct.new(:code, :body)

    OPEN_TIMEOUT = 5
    READ_TIMEOUT = 10
    WRITE_TIMEOUT = 10

    # Receivers verify a delivery by recomputing
    #   HMAC-SHA256(secret, "#{X-Prose-Timestamp}.#{raw_body}")
    # comparing it to X-Prose-Signature ("sha256=<hex>") in constant time, and
    # rejecting stale timestamps to prevent replay.
    def self.signature(secret, timestamp, body)
      "sha256=#{OpenSSL::HMAC.hexdigest("SHA256", secret, "#{timestamp}.#{body}")}"
    end

    def self.post(url, body:, secret:, event: nil, delivery_id: nil)
      new(url, body: body, secret: secret, event: event, delivery_id: delivery_id).post
    end

    def initialize(url, body:, secret:, event: nil, delivery_id: nil)
      @url = url
      @body = body
      @secret = secret
      @event = event
      @delivery_id = delivery_id
    end

    def post
      uri = URI(@url)
      raise DeliveryError, "Webhook URL must be http or https" unless uri.is_a?(URI::HTTP)

      http = Net::HTTP.new(uri.hostname, uri.port)
      # Connect to the vetted IP so a DNS rebind between check and connect can't
      # redirect the request to an internal address. Redirects are not followed.
      http.ipaddr = UrlGuard.resolve!(uri.hostname)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = OPEN_TIMEOUT
      http.read_timeout = READ_TIMEOUT
      http.write_timeout = WRITE_TIMEOUT

      response = http.request(build_request(uri))
      code = response.code.to_i

      unless code.between?(200, 299)
        raise DeliveryError.new("Webhook endpoint returned #{code}", response_code: code)
      end

      Response.new(code, response.body)
    rescue DeliveryError
      raise
    rescue StandardError => e
      raise DeliveryError, e.message
    end

    private

    def build_request(uri)
      timestamp = Time.current.to_i
      request = Net::HTTP::Post.new(uri.request_uri)
      request["Content-Type"] = "application/json"
      request["User-Agent"] = "Prose-Webhooks/1.0"
      request["X-Prose-Timestamp"] = timestamp.to_s
      request["X-Prose-Signature"] = self.class.signature(@secret, timestamp, @body)
      request["X-Prose-Event"] = @event if @event
      request["X-Prose-Delivery"] = @delivery_id if @delivery_id
      request.body = @body
      request
    end
  end
end
