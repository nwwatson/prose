# A stand-in for Net::HTTP that records the request it was given and either
# returns `outcome`, yields it (block form, as used for streamed bodies), or
# raises it when it is an exception.
class FakeHTTP
  attr_accessor :use_ssl, :open_timeout, :read_timeout, :write_timeout, :ipaddr, :cert_store
  attr_reader :last_request

  def initialize(outcome)
    @outcome = outcome
  end

  def request(request)
    @last_request = request
    raise @outcome if @outcome.is_a?(Exception)

    block_given? ? yield(@outcome) : @outcome
  end

  def get(request_uri)
    @last_request = request_uri
    raise @outcome if @outcome.is_a?(Exception)

    @outcome
  end
end

module HttpHelper
  # Routes `Net::HTTP.new` to a FakeHTTP and makes the SSRF guard resolve every
  # host to `resolved_ip`. Yields the FakeHTTP so tests can inspect the request.
  def with_fake_http(outcome, resolved_ip: "93.184.216.34")
    fake = FakeHTTP.new(outcome)
    with_singleton_stub(Net::HTTP, :new, ->(*) { fake }) do
      with_singleton_stub(Webhooks::UrlGuard, :resolve, ->(_host) { [ resolved_ip ] }) { yield fake }
    end
  end

  def stub_oembed_fetch(data, &block)
    with_singleton_stub(OembedFetcher, :fetch, ->(*) { data }, &block)
  end

  def stub_client_chat(fake_chat, &block)
    with_singleton_stub(Ai::Client, :chat, ->(*) { fake_chat }, &block)
  end
end
