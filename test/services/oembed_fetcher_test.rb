require "test_helper"

class OembedFetcherTest < ActiveSupport::TestCase
  FakeResponse = Struct.new(:body)

  test "returns parsed JSON on success" do
    result = with_fake_http(FakeResponse.new({ "title" => "Cool Video" }.to_json)) do
      OembedFetcher.fetch("https://www.youtube.com/oembed?url=foo&format=json")
    end

    assert_equal({ "title" => "Cool Video" }, result)
  end

  test "returns an empty hash and logs a warning when the response isn't JSON" do
    result = with_fake_http(FakeResponse.new("<html>not json</html>")) do
      assert_logs_warning { OembedFetcher.fetch("https://www.youtube.com/oembed?url=foo&format=json") }
    end

    assert_equal({}, result)
  end

  test "returns an empty hash and logs a warning on a network error" do
    result = with_fake_http(SocketError.new("failed to resolve host")) do
      assert_logs_warning { OembedFetcher.fetch("https://www.youtube.com/oembed?url=foo&format=json") }
    end

    assert_equal({}, result)
  end

  private

  def assert_logs_warning
    logged = nil
    result = with_singleton_stub(Rails.logger, :warn, ->(message) { logged = message }) { yield }
    assert logged, "expected a warning to be logged"
    result
  end
end
