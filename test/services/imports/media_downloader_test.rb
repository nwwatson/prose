require "test_helper"

class Imports::MediaDownloaderTest < ActiveSupport::TestCase
  PNG = "\x89PNG\r\n\x1A\n".b + ("\x00".b * 32)

  # Routes requests by host to canned responses and records connections.
  class FakeHTTP
    attr_accessor :ipaddr, :use_ssl, :open_timeout, :read_timeout
    attr_reader :host

    def initialize(host, responses, log)
      @host = host
      @responses = responses
      @log = log
    end

    def start
      yield self
    end

    def request(request)
      @log << { host: @host, path: request.path, ipaddr: ipaddr }
      yield @responses.fetch("#{@host}#{request.path}")
    end
  end

  setup do
    @responses = {}
    @log = []
    @dns = { "wp.example.com" => [ "93.184.216.34" ], "cdn.example.com" => [ "93.184.216.35" ], "internal.example.com" => [ "10.0.0.5" ] }
    @downloader = Imports::MediaDownloader.new
  end

  test "downloads an image into a blob and connects to the vetted IP" do
    @responses["wp.example.com/uploads/cat%20photo.png"] = ok(PNG, "image/png")

    blob = with_fakes { @downloader.download("https://wp.example.com/uploads/cat%20photo.png") }

    assert_kind_of ActiveStorage::Blob, blob
    assert_equal "cat photo.png", blob.filename.to_s
    assert_equal "image/png", blob.content_type
    assert_equal PNG, blob.download
    assert_equal "93.184.216.34", @log.first[:ipaddr]
    assert_equal [ blob ], @downloader.created_blobs
  end

  test "memoizes by url" do
    @responses["wp.example.com/a.png"] = ok(PNG, "image/png")

    first, second = with_fakes { [ @downloader.download("https://wp.example.com/a.png"), @downloader.download("https://wp.example.com/a.png") ] }

    assert_equal first, second
    assert_equal 1, @log.size
  end

  test "follows redirects and re-checks each hop" do
    @responses["wp.example.com/a.png"] = redirect("https://cdn.example.com/a.png")
    @responses["cdn.example.com/a.png"] = ok(PNG, "image/png")

    blob = with_fakes { @downloader.download("https://wp.example.com/a.png") }

    assert blob
    assert_equal [ "wp.example.com", "cdn.example.com" ], @log.map { |entry| entry[:host] }
  end

  test "refuses a redirect to a private address" do
    @responses["wp.example.com/a.png"] = redirect("https://internal.example.com/secret.png")

    assert_nil with_fakes { @downloader.download("https://wp.example.com/a.png") }
    assert_equal [ "wp.example.com" ], @log.map { |entry| entry[:host] }
    assert_equal 1, @downloader.failures.size
  end

  test "refuses private hosts and non-http urls without connecting" do
    assert_nil with_fakes { @downloader.download("http://127.0.0.1/a.png") }
    assert_nil with_fakes { @downloader.download("file:///etc/passwd") }
    assert_nil with_fakes { @downloader.download("http://localhost/a.png") }
    assert_empty @log
  end

  test "stops after too many redirects" do
    @responses["wp.example.com/loop.png"] = redirect("https://wp.example.com/loop.png")

    assert_nil with_fakes { @downloader.download("https://wp.example.com/loop.png") }
    assert_equal Imports::MediaDownloader::MAX_REDIRECTS + 1, @log.size
  end

  test "rejects content that is not really an image" do
    @responses["wp.example.com/fake.png"] = ok("<html>error</html>", "image/png")

    assert_nil with_fakes { @downloader.download("https://wp.example.com/fake.png") }
    assert_match(/Not an image/, @downloader.failures.first[:error])
  end

  test "rejects oversized files" do
    @responses["wp.example.com/huge.png"] = ok(PNG, "image/png", content_length: Imports::MediaDownloader::MAX_BYTES + 1)

    assert_nil with_fakes { @downloader.download("https://wp.example.com/huge.png") }
    assert_match(/too large/, @downloader.failures.first[:error])
  end

  test "returns nil on http errors" do
    @responses["wp.example.com/missing.png"] = Net::HTTPNotFound.new("1.1", "404", "Not Found")

    assert_nil with_fakes { @downloader.download("https://wp.example.com/missing.png") }
    assert_match(/HTTP 404/, @downloader.failures.first[:error])
  end

  private

  def ok(body, content_type, content_length: nil)
    response = Net::HTTPOK.new("1.1", "200", "OK")
    response["content-type"] = content_type
    response["content-length"] = content_length.to_s if content_length
    response.define_singleton_method(:read_body) { |&block| block.call(body) }
    response
  end

  def redirect(location)
    response = Net::HTTPFound.new("1.1", "302", "Found")
    response["location"] = location
    response
  end

  def with_fakes
    responses, log, dns = @responses, @log, @dns
    original_new = Net::HTTP.method(:new)
    original_resolve = Webhooks::UrlGuard.method(:resolve)
    Net::HTTP.define_singleton_method(:new) { |host, *_args| FakeHTTP.new(host, responses, log) }
    Webhooks::UrlGuard.define_singleton_method(:resolve) { |host| dns.fetch(host, [ host ]) }
    yield
  ensure
    Net::HTTP.define_singleton_method(:new, original_new)
    Webhooks::UrlGuard.define_singleton_method(:resolve, original_resolve)
  end
end
