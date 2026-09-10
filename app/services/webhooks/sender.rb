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

    def self.post(url, body:, secret:)
      new(url, body: body, secret: secret).post
    end

    def initialize(url, body:, secret:)
      @url = url
      @body = body
      @secret = secret
    end

    def post
      uri = URI(@url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = 5
      http.read_timeout = 10

      request = Net::HTTP::Post.new(uri.request_uri)
      request["Content-Type"] = "application/json"
      request["X-Prose-Signature"] = signature
      request.body = @body

      response = http.request(request)
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

    def signature
      OpenSSL::HMAC.hexdigest("SHA256", @secret, @body)
    end
  end
end
