require "test_helper"

module ActivityPub
  class HttpClientTest < ActiveSupport::TestCase
    include ActivityPubTestHelper

    class FakeResponse
      attr_reader :code

      def initialize(code, body)
        @code = code
        @body = body
      end

      def read_body
        yield @body
      end
    end

    class FakeHTTP
      attr_accessor :use_ssl, :open_timeout, :read_timeout, :write_timeout, :ipaddr
      attr_reader :last_request

      def initialize(response)
        @response = response
      end

      def request(request)
        @last_request = request
        yield @response
      end
    end

    def with_fake_http(response, resolved_ip: "93.184.216.34")
      fake = FakeHTTP.new(response)
      with_singleton_stub(Net::HTTP, :new, ->(*) { fake }) do
        with_singleton_stub(Webhooks::UrlGuard, :resolve, ->(_host) { [ resolved_ip ] }) { yield fake }
      end
    end

    setup { enable_federation! }

    test "post sends a signed ActivityPub request pinned to the vetted IP" do
      with_fake_http(FakeResponse.new("202", "")) do |fake|
        HttpClient.post("https://remote.example/inbox", "{}")

        request = fake.last_request
        assert_equal "93.184.216.34", fake.ipaddr
        assert_equal "application/activity+json", request["Content-Type"]
        assert_equal Signature.digest("{}"), request["Digest"]
        assert_match(/keyId="#{Regexp.escape(Urls.key_id)}"/, request["Signature"])
      end
    end

    test "get parses JSON" do
      with_fake_http(FakeResponse.new("200", { "id" => "x" }.to_json)) do
        assert_equal({ "id" => "x" }, HttpClient.get("https://remote.example/actor"))
      end
    end

    test "non-2xx responses raise with the status" do
      with_fake_http(FakeResponse.new("410", "")) do
        error = assert_raises(HttpClient::Error) { HttpClient.post("https://remote.example/inbox", "{}") }
        assert_equal 410, error.status
      end
    end

    test "oversized responses are rejected" do
      with_fake_http(FakeResponse.new("200", "a" * (HttpClient::MAX_RESPONSE_BYTES + 1))) do
        assert_raises(HttpClient::Error) { HttpClient.get("https://remote.example/actor") }
      end
    end

    test "private addresses are refused" do
      with_fake_http(FakeResponse.new("200", "{}"), resolved_ip: "10.0.0.5") do
        assert_raises(HttpClient::Error) { HttpClient.get("https://remote.example/actor") }
      end
    end
  end
end
