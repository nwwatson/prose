require "test_helper"

module Webhooks
  class UrlGuardTest < ActiveSupport::TestCase
    test "blocks loopback, private, link-local, and reserved addresses" do
      %w[127.0.0.1 10.1.2.3 172.31.255.255 192.168.0.1 169.254.169.254 100.64.0.1 0.0.0.0 224.0.0.1
         ::1 :: fe80::1 fd00::1 ::ffff:10.0.0.1].each do |ip|
        assert UrlGuard.blocked_ip?(ip), "expected #{ip} to be blocked"
      end
    end

    test "allows public addresses" do
      %w[93.184.216.34 8.8.8.8 2606:4700:4700::1111].each do |ip|
        assert_not UrlGuard.blocked_ip?(ip), "expected #{ip} to be allowed"
      end
    end

    test "resolve! returns a public literal address" do
      assert_equal "8.8.8.8", UrlGuard.resolve!("8.8.8.8")
    end

    test "resolve! rejects a hostname that resolves to a private address" do
      with_resolution([ "93.184.216.34", "10.0.0.1" ]) do
        assert_raises(UrlGuard::UnsafeUrlError) { UrlGuard.resolve!("rebind.example.com") }
      end
    end

    test "resolve! rejects an unresolvable hostname" do
      with_resolution([]) do
        assert_raises(UrlGuard::UnsafeUrlError) { UrlGuard.resolve!("nope.example.com") }
      end
    end

    test "resolve! returns the resolved public address" do
      with_resolution([ "93.184.216.34" ]) do
        assert_equal "93.184.216.34", UrlGuard.resolve!("example.com")
      end
    end

    private

    def with_resolution(addresses)
      infos = addresses.map { |ip| Addrinfo.tcp(ip, 0) }
      original = Addrinfo.method(:getaddrinfo)
      Addrinfo.define_singleton_method(:getaddrinfo) { |*_args, **_kwargs| infos }
      yield
    ensure
      Addrinfo.define_singleton_method(:getaddrinfo, original)
    end
  end
end
