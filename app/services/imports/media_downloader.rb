module Imports
  # Downloads remote images referenced by imported content and stores them as
  # Active Storage blobs.
  #
  # Import files are user-supplied, so every URL — including each redirect
  # hop — is vetted with Webhooks::UrlGuard and the connection is pinned to the
  # vetted IP, exactly like outbound webhooks. Responses are size-capped while
  # streaming and must be images. Returns nil (never raises) on any failure so
  # the caller can keep the original remote URL.
  class MediaDownloader
    class DownloadError < StandardError; end

    MAX_BYTES = 10.megabytes
    MAX_REDIRECTS = 3
    OPEN_TIMEOUT = 5
    READ_TIMEOUT = 15

    attr_reader :failures, :created_blobs

    def initialize
      @cache = {}
      @failures = []
      @created_blobs = []
    end

    # Memoized per URL so an image used by several posts is stored once.
    def download(url)
      url = url.to_s.strip
      return @cache[url] if @cache.key?(url)

      @cache[url] = fetch_blob(url)
    end

    private

    def fetch_blob(url)
      body, content_type, final_uri = fetch(URI.parse(url))
      raise DownloadError, "Not an image (#{content_type})" unless image?(content_type, body)

      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new(body),
        filename: filename_for(final_uri, content_type),
        content_type: content_type
      )
      @created_blobs << blob
      blob
    rescue URI::InvalidURIError, DownloadError, Webhooks::UrlGuard::UnsafeUrlError,
           Net::OpenTimeout, Net::ReadTimeout, SocketError, SystemCallError, IOError, OpenSSL::SSL::SSLError => e
      @failures << { url: url, error: e.message }
      Rails.logger.warn("[Imports::MediaDownloader] #{url}: #{e.class}: #{e.message}")
      nil
    end

    def fetch(uri, redirects = 0)
      raise DownloadError, "Only http and https URLs are allowed" unless uri.is_a?(URI::HTTP) && uri.host.present?

      http = Net::HTTP.new(uri.hostname, uri.port)
      http.ipaddr = Webhooks::UrlGuard.resolve!(uri.hostname)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = OPEN_TIMEOUT
      http.read_timeout = READ_TIMEOUT

      http.start do
        request = Net::HTTP::Get.new(uri.request_uri, "User-Agent" => "Prose-Importer/1.0")
        http.request(request) do |response|
          case response
          when Net::HTTPRedirection
            raise DownloadError, "Too many redirects" if redirects >= MAX_REDIRECTS

            return fetch(uri.merge(response["location"].to_s), redirects + 1)
          when Net::HTTPSuccess
            return [ read_limited(response), response.content_type.to_s, uri ]
          else
            raise DownloadError, "HTTP #{response.code}"
          end
        end
      end
    end

    def read_limited(response)
      raise DownloadError, "File too large" if response.content_length.to_i > MAX_BYTES

      body = +""
      response.read_body do |chunk|
        body << chunk
        raise DownloadError, "File too large" if body.bytesize > MAX_BYTES
      end
      body
    end

    # Trust the sniffed type over the header: a server can claim image/png for
    # an HTML error page.
    def image?(content_type, body)
      sniffed = Marcel::MimeType.for(StringIO.new(body))
      content_type.start_with?("image/") && sniffed.start_with?("image/")
    end

    def filename_for(uri, content_type)
      name = CGI.unescape(File.basename(uri.path.to_s))
      return name if name.present? && name.include?(".")

      extension = Rack::Mime::MIME_TYPES.invert[content_type] || ""
      "image#{extension}"
    end
  end
end
