require "test_helper"

module Webhooks
  class SenderTest < ActiveSupport::TestCase
    FakeResponse = Struct.new(:code, :body)

    class FakeHTTP
      attr_accessor :use_ssl, :open_timeout, :read_timeout, :write_timeout, :ipaddr
      attr_reader :last_request

      def initialize(outcome)
        @outcome = outcome
      end

      def request(request)
        @last_request = request
        raise @outcome if @outcome.is_a?(Exception)

        @outcome
      end
    end

    def with_fake_http(outcome, resolved_ip: "93.184.216.34")
      fake = FakeHTTP.new(outcome)
      original_new = Net::HTTP.method(:new)
      original_resolve = UrlGuard.method(:resolve)
      Net::HTTP.define_singleton_method(:new) { |*_args| fake }
      UrlGuard.define_singleton_method(:resolve) { |_host| [ resolved_ip ] }
      yield fake
    ensure
      Net::HTTP.define_singleton_method(:new, original_new)
      UrlGuard.define_singleton_method(:resolve, original_resolve)
    end

    test "returns a response on success" do
      with_fake_http(FakeResponse.new("200", "ok")) do
        response = Webhooks::Sender.post("https://example.com/hook", body: "{}", secret: "s3cret")
        assert_equal 200, response.code
      end
    end

    test "signs the timestamp and body and connects to the vetted IP" do
      freeze_time do
        with_fake_http(FakeResponse.new("200", "ok")) do |http|
          Webhooks::Sender.post("https://example.com/hook", body: '{"a":1}', secret: "s3cret", event: "post.published", delivery_id: "abc")

          request = http.last_request
          timestamp = Time.current.to_i
          expected = "sha256=" + OpenSSL::HMAC.hexdigest("SHA256", "s3cret", "#{timestamp}.{\"a\":1}")
          assert_equal timestamp.to_s, request["X-Prose-Timestamp"]
          assert_equal expected, request["X-Prose-Signature"]
          assert_equal "post.published", request["X-Prose-Event"]
          assert_equal "abc", request["X-Prose-Delivery"]
          assert_equal "93.184.216.34", http.ipaddr
          assert http.write_timeout.present?
        end
      end
    end

    test "refuses to deliver to a host resolving to a private address" do
      with_fake_http(FakeResponse.new("200", "ok"), resolved_ip: "169.254.169.254") do |http|
        assert_raises(Webhooks::Sender::DeliveryError) do
          Webhooks::Sender.post("https://example.com/hook", body: "{}", secret: "s3cret")
        end
        assert_nil http.last_request
      end
    end

    test "raises DeliveryError on a non-2xx response" do
      with_fake_http(FakeResponse.new("500", "boom")) do
        error = assert_raises(Webhooks::Sender::DeliveryError) do
          Webhooks::Sender.post("https://example.com/hook", body: "{}", secret: "s3cret")
        end
        assert_equal 500, error.response_code
      end
    end

    test "treats redirects as failures instead of following them" do
      with_fake_http(FakeResponse.new("302", "")) do |http|
        error = assert_raises(Webhooks::Sender::DeliveryError) do
          Webhooks::Sender.post("https://example.com/hook", body: "{}", secret: "s3cret")
        end
        assert_equal 302, error.response_code
      end
    end

    test "raises DeliveryError on a network error" do
      with_fake_http(Errno::ECONNREFUSED.new) do
        assert_raises(Webhooks::Sender::DeliveryError) do
          Webhooks::Sender.post("https://example.com/hook", body: "{}", secret: "s3cret")
        end
      end
    end
  end
end
