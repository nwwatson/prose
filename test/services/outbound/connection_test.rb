require "test_helper"
require "socket"

module Outbound
  class ConnectionTest < ActiveSupport::TestCase
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

    # `.invalid` never resolves (RFC 2606), so a request that reaches the local
    # server can only have got there through the pinned IP.
    UNRESOLVABLE_HOST = "pinned.invalid"

    test "connects to the vetted IP with timeouts set" do
      with_fake_http(FakeResponse.new("200", "ok")) do |http|
        response = Connection.request(URI("https://example.com/x"), Net::HTTP::Get.new("/x"), max_bytes: 10)

        assert_equal 200, response.code
        assert_equal "ok", response.body
        assert_equal "93.184.216.34", http.ipaddr
        assert http.use_ssl
        assert_equal Connection::OPEN_TIMEOUT, http.open_timeout
        assert_equal Connection::READ_TIMEOUT, http.read_timeout
        assert_equal Connection::WRITE_TIMEOUT, http.write_timeout
      end
    end

    test "refuses a host resolving to a disallowed address before sending anything" do
      with_fake_http(FakeResponse.new("200", "ok"), resolved_ip: "169.254.169.254") do |http|
        assert_raises(UrlGuard::UnsafeUrlError) do
          Connection.request(URI("https://example.com/x"), Net::HTTP::Get.new("/x"), max_bytes: 10)
        end
        assert_nil http.last_request
      end
    end

    test "refuses a literal private address without resolving" do
      assert_raises(UrlGuard::UnsafeUrlError) do
        Connection.request(URI("http://127.0.0.1/x"), Net::HTTP::Get.new("/x"), max_bytes: 10)
      end
    end

    test "rejects non-http URLs" do
      assert_raises(ArgumentError) do
        Connection.request(URI("ftp://example.com/x"), Net::HTTP::Get.new("/x"), max_bytes: 10)
      end
    end

    test "raises ResponseTooLarge once the body passes the cap and stops reading" do
      response = FakeResponse.new("200", "a" * 6, "b" * 6, "c" * 6)
      with_fake_http(response) do
        error = assert_raises(Connection::ResponseTooLarge) do
          Connection.request(URI("https://example.com/x"), Net::HTTP::Get.new("/x"), max_bytes: 10)
        end
        assert_equal 200, error.code
      end
      assert_equal 2, response.chunks_read
    end

    test "truncates at the cap and stops reading when asked to" do
      response = FakeResponse.new("200", "a" * 6, "b" * 6, "c" * 6)
      result = with_fake_http(response) do
        Connection.request(URI("https://example.com/x"), Net::HTTP::Get.new("/x"), max_bytes: 10, truncate: true)
      end

      assert_equal 200, result.code
      assert_equal "aaaaaabbbb", result.body
      assert result.truncated
      assert_equal 2, response.chunks_read
    end

    # The tests below use a real socket on loopback. The guard is told to vet
    # loopback (it never would), so the only thing under test is what
    # Net::HTTP does with the vetted IP.

    test "the connection goes to the pinned IP, not the URL's hostname" do
      with_local_server("HTTP/1.1 204 No Content\r\nContent-Length: 0\r\n\r\n") do |port, requests|
        response = Connection.request(URI("http://#{UNRESOLVABLE_HOST}:#{port}/hook"), Net::HTTP::Post.new("/hook"), max_bytes: 10)

        assert_equal 204, response.code
        assert_equal 1, requests.size
        assert_match(/\AHost: #{Regexp.escape(UNRESOLVABLE_HOST)}:#{port}\r\n/i, requests.pop[/^Host:.*\r\n/i])
      end
    end

    test "a redirect is returned to the caller, never followed" do
      redirect = "HTTP/1.1 302 Found\r\nLocation: http://169.254.169.254/latest/meta-data/\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
      with_local_server(redirect) do |port, requests|
        response = Connection.request(URI("http://#{UNRESOLVABLE_HOST}:#{port}/"), Net::HTTP::Get.new("/"), max_bytes: 10)

        assert_equal 302, response.code
        assert_equal 1, requests.size
      end
    end

    test "never buffers more than the cap from a huge response" do
      huge = "HTTP/1.1 200 OK\r\nContent-Length: #{20.megabytes}\r\n\r\n" + ("x" * 20.megabytes)
      with_local_server(huge) do |port, _requests|
        response = Connection.request(URI("http://#{UNRESOLVABLE_HOST}:#{port}/"), Net::HTTP::Get.new("/"), max_bytes: 1.kilobyte, truncate: true)

        assert_equal 200, response.code
        assert_equal 1.kilobyte, response.body.bytesize
        assert response.truncated
      end
    end

    private

    # Serves `reply` to every connection on 127.0.0.1 and yields the port and a
    # Queue of the raw request heads received (each is pushed before the reply
    # is written), with the guard vetting loopback.
    def with_local_server(reply)
      server = TCPServer.new("127.0.0.1", 0)
      requests = Queue.new
      thread = Thread.new do
        loop do
          client = server.accept
          head = +""
          head << client.readpartial(4096) until head.include?("\r\n\r\n")
          requests << head
          begin
            client.write(reply)
          rescue Errno::EPIPE, Errno::ECONNRESET, IOError
            # The client stopped reading at its cap and hung up.
          ensure
            client.close
          end
        end
      rescue IOError, Errno::EBADF
        # Server closed.
      end

      with_singleton_stub(UrlGuard, :resolve!, ->(_host) { "127.0.0.1" }) do
        yield server.addr[1], requests
      end
    ensure
      server&.close
      thread&.join(2)
      thread&.kill
    end
  end
end
