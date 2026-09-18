require "ipaddr"
require "socket"

module Webhooks
  # Guards outbound requests (webhook deliveries and import media downloads)
  # against SSRF: URLs must not point at loopback, private, link-local (cloud
  # metadata), or otherwise reserved addresses — either literally or via DNS
  # resolution.
  module UrlGuard
    class UnsafeUrlError < StandardError; end

    DNS_TIMEOUT = 5

    BLOCKED_HOSTNAME = /\A(localhost|.+\.localhost|.+\.local|.+\.internal)\.?\z/i

    BLOCKED_RANGES = %w[
      0.0.0.0/8 10.0.0.0/8 100.64.0.0/10 127.0.0.0/8 169.254.0.0/16 172.16.0.0/12
      192.0.0.0/24 192.0.2.0/24 192.168.0.0/16 198.18.0.0/15 198.51.100.0/24
      203.0.113.0/24 224.0.0.0/4 240.0.0.0/4
      ::/128 ::1/128 64:ff9b::/96 100::/64 2001:db8::/32 fc00::/7 fe80::/10 ff00::/8
    ].map { |cidr| IPAddr.new(cidr) }.freeze

    module_function

    # True when the host is a blocked name or a literal IP in a blocked range.
    # Does not perform DNS resolution (used for model validation).
    def blocked_host?(host)
      return true if host.blank?

      host = host.to_s.delete_prefix("[").delete_suffix("]")
      return true if host.match?(BLOCKED_HOSTNAME)

      ip_literal?(host) && blocked_ip?(host)
    end

    def blocked_ip?(ip)
      addr = IPAddr.new(ip.to_s)
      addr = addr.native if addr.ipv6? && (addr.ipv4_mapped? || addr.ipv4_compat?)
      BLOCKED_RANGES.any? { |range| range.family == addr.family && range.include?(addr) }
    rescue IPAddr::InvalidAddressError
      true
    end

    # Resolves the host and returns an IP address that is safe to connect to.
    # Raises UnsafeUrlError if the host is blocked or any resolved address is.
    def resolve!(host)
      raise UnsafeUrlError, "Host is not allowed" if blocked_host?(host)

      addresses = resolve(host.to_s.delete_prefix("[").delete_suffix("]"))
      raise UnsafeUrlError, "Host could not be resolved" if addresses.empty?
      raise UnsafeUrlError, "Host resolves to a disallowed address" if addresses.any? { |ip| blocked_ip?(ip) }

      addresses.first
    end

    def resolve(host)
      return [ host ] if ip_literal?(host)

      Addrinfo.getaddrinfo(host, nil, nil, :STREAM, timeout: DNS_TIMEOUT).map(&:ip_address).uniq
    rescue SocketError, IOError, SystemCallError
      []
    end

    def ip_literal?(host)
      IPAddr.new(host)
      true
    rescue IPAddr::InvalidAddressError
      false
    end
  end
end
