require "test_helper"
require "socket"

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

  test "sets short open and read timeouts" do
    with_fake_http(FakeResponse.new("{}")) do |http|
      OembedFetcher.fetch("https://www.youtube.com/oembed?url=foo&format=json")

      assert_equal 5, http.open_timeout
      assert_equal 10, http.read_timeout
    end
  end

  test "returns an empty hash within the timeout when the provider stalls" do
    # Accepts the connection but never answers, so the TLS handshake hangs.
    server = TCPServer.new("127.0.0.1", 0)
    with_const(OembedFetcher, :OPEN_TIMEOUT, 0.2) do
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      result = assert_logs_warning { OembedFetcher.fetch("https://127.0.0.1:#{server.addr[1]}/oembed") }

      assert_equal({}, result)
      assert_operator Process.clock_gettime(Process::CLOCK_MONOTONIC) - started, :<, 2
    end
  ensure
    server&.close
  end

  private

  def assert_logs_warning
    logged = nil
    result = with_singleton_stub(Rails.logger, :warn, ->(message) { logged = message }) { yield }
    assert logged, "expected a warning to be logged"
    result
  end
end
