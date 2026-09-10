require "test_helper"

module Webhooks
  class SenderTest < ActiveSupport::TestCase
    FakeResponse = Struct.new(:code, :body)

    class FakeHTTP
      attr_accessor :use_ssl, :open_timeout, :read_timeout

      def initialize(outcome)
        @outcome = outcome
      end

      def request(_request)
        raise @outcome if @outcome.is_a?(Exception)

        @outcome
      end
    end

    def with_fake_http(outcome)
      original_new = Net::HTTP.method(:new)
      Net::HTTP.define_singleton_method(:new) { |*_args| FakeHTTP.new(outcome) }
      yield
    ensure
      Net::HTTP.define_singleton_method(:new, original_new)
    end

    test "returns a response on success" do
      with_fake_http(FakeResponse.new("200", "ok")) do
        response = Webhooks::Sender.post("https://example.com/hook", body: "{}", secret: "s3cret")
        assert_equal 200, response.code
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

    test "raises DeliveryError on a network error" do
      with_fake_http(Errno::ECONNREFUSED.new) do
        assert_raises(Webhooks::Sender::DeliveryError) do
          Webhooks::Sender.post("https://example.com/hook", body: "{}", secret: "s3cret")
        end
      end
    end
  end
end
