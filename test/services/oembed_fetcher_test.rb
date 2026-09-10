require "test_helper"

class OembedFetcherTest < ActiveSupport::TestCase
  class FakeHttp
    attr_accessor :use_ssl, :cert_store

    def initialize(response_body: nil, error: nil)
      @response_body = response_body
      @error = error
    end

    def get(_request_uri)
      raise @error if @error

      Struct.new(:body).new(@response_body)
    end
  end

  test "returns parsed JSON on success" do
    http = FakeHttp.new(response_body: { "title" => "Cool Video" }.to_json)

    result = stub_net_http(http) { OembedFetcher.fetch("https://www.youtube.com/oembed?url=foo&format=json") }

    assert_equal({ "title" => "Cool Video" }, result)
  end

  test "returns an empty hash and logs a warning when the response isn't JSON" do
    http = FakeHttp.new(response_body: "<html>not json</html>")

    result = stub_net_http(http) do
      assert_logs_warning { OembedFetcher.fetch("https://www.youtube.com/oembed?url=foo&format=json") }
    end

    assert_equal({}, result)
  end

  test "returns an empty hash and logs a warning on a network error" do
    http = FakeHttp.new(error: SocketError.new("failed to resolve host"))

    result = stub_net_http(http) do
      assert_logs_warning { OembedFetcher.fetch("https://www.youtube.com/oembed?url=foo&format=json") }
    end

    assert_equal({}, result)
  end

  private

  def stub_net_http(fake_http)
    original_new = Net::HTTP.method(:new)
    Net::HTTP.define_singleton_method(:new) { |*| fake_http }
    yield
  ensure
    Net::HTTP.define_singleton_method(:new, original_new)
  end

  def assert_logs_warning
    logged = nil
    original_warn = Rails.logger.method(:warn)
    Rails.logger.define_singleton_method(:warn) { |message| logged = message }
    result = yield
    assert logged, "expected a warning to be logged"
    result
  ensure
    Rails.logger.define_singleton_method(:warn, original_warn)
  end
end
