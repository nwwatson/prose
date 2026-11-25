require "test_helper"

module Webhooks
  class SenderTest < ActiveSupport::TestCase
    class FakeResponse
      attr_reader :code, :chunks_read

      def initialize(code, *chunks)
        @code = code
        @chunks = chunks
        @chunks_read = 0
      end

      def read_body
        @chunks.each do |chunk|
          @chunks_read += 1
          yield chunk
        end
      end
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

    test "reads no more than the cap from a large response and still succeeds" do
      cap = Webhooks::Sender::MAX_RESPONSE_BYTES
      fake = FakeResponse.new("200", "a" * cap, "b", "c" * cap)
      with_fake_http(fake) do
        response = Webhooks::Sender.post("https://example.com/hook", body: "{}", secret: "s3cret")
        assert_equal 200, response.code
        assert_equal cap, response.body.bytesize
      end
      assert_equal 2, fake.chunks_read, "expected reading to stop once the cap was passed"
    end

    test "rejects non-http URLs" do
      assert_raises(Webhooks::Sender::DeliveryError) do
        Webhooks::Sender.post("file:///etc/passwd", body: "{}", secret: "s3cret")
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
