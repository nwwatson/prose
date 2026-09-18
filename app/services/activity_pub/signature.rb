module ActivityPub
  # HTTP Signatures (draft-cavage-http-signatures-12), the scheme Mastodon and
  # most of the fediverse use to authenticate server-to-server requests: an
  # RSA-SHA256 signature over selected headers, plus a SHA-256 Digest of the
  # body so the payload can't be swapped under a valid signature.
  module Signature
    class VerificationError < StandardError; end

    MAX_AGE = 12.hours
    CLOCK_SKEW = 1.hour
    SUPPORTED_ALGORITHMS = [ nil, "rsa-sha256", "hs2019" ].freeze

    module_function

    def digest(body)
      "SHA-256=#{Base64.strict_encode64(OpenSSL::Digest::SHA256.digest(body))}"
    end

    # Returns the headers to add to an outgoing request (Host, Date, Digest when
    # there's a body, and Signature).
    def sign(method:, url:, key:, key_id:, body: nil, date: Time.current)
      uri = URI(url)
      headers = { "host" => authority(uri), "date" => date.httpdate }
      headers["digest"] = digest(body) if body

      names = [ "(request-target)", *headers.keys ]
      string = signing_string(method, uri.request_uri, names) { |name| headers[name] }
      signature = Base64.strict_encode64(key.sign(OpenSSL::Digest::SHA256.new, string))

      headers.transform_keys(&:capitalize).merge(
        "Signature" => %(keyId="#{key_id}",algorithm="rsa-sha256",headers="#{names.join(" ")}",signature="#{signature}")
      )
    end

    def signing_string(method, request_target, names)
      names.map do |name|
        if name == "(request-target)"
          "(request-target): #{method.to_s.downcase} #{request_target}"
        else
          value = yield(name)
          raise VerificationError, "Signed header #{name} is missing" if value.nil?

          "#{name}: #{value}"
        end
      end.join("\n")
    end

    def authority(uri)
      uri.port == uri.default_port ? uri.host : "#{uri.host}:#{uri.port}"
    end

    # Verifies an incoming request. `headers` is anything that answers
    # `headers["digest"]` (ActionDispatch::Http::Headers, or a lowercase-keyed Hash).
    class Verifier
      attr_reader :params

      def initialize(method:, path:, headers:, body:)
        @method = method
        @path = path
        @headers = headers
        @body = body
        @params = parse(headers["signature"])
      end

      def key_id
        @params.fetch("keyId") { raise VerificationError, "Signature has no keyId" }
      end

      def verify!(public_key_pem)
        raise VerificationError, "Unsupported algorithm" unless SUPPORTED_ALGORITHMS.include?(@params["algorithm"])

        names = @params.fetch("headers", "date").downcase.split
        required = [ "(request-target)", "host", "date" ]
        required << "digest" if @body.present?
        missing = required - names
        raise VerificationError, "Signature must cover #{missing.join(", ")}" if missing.any?

        verify_date!
        verify_digest! if @body.present?

        key = OpenSSL::PKey::RSA.new(public_key_pem.to_s)
        signature = Base64.decode64(@params.fetch("signature") { raise VerificationError, "Signature is empty" })
        string = Signature.signing_string(@method, @path, names) { |name| @headers[name] }
        raise VerificationError, "Signature does not match" unless key.verify(OpenSSL::Digest::SHA256.new, signature, string)

        true
      rescue OpenSSL::PKey::PKeyError
        raise VerificationError, "Actor public key is invalid"
      end

      private

      def parse(header)
        raise VerificationError, "Request is not signed" if header.blank?

        header.to_s.scan(/(\w+)="([^"]*)"/).to_h
      end

      def verify_date!
        date = Time.httpdate(@headers["date"].to_s)
        raise VerificationError, "Signed date is outside the allowed window" unless date.between?(MAX_AGE.ago, CLOCK_SKEW.from_now)
      rescue ArgumentError
        raise VerificationError, "Signed date is invalid"
      end

      def verify_digest!
        expected = Signature.digest(@body)
        provided = @headers["digest"].to_s.split(",").map(&:strip).find { |value| value.start_with?("SHA-256=") }
        raise VerificationError, "Digest does not match body" unless provided && ActiveSupport::SecurityUtils.secure_compare(provided, expected)
      end
    end
  end
end
