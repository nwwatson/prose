require "test_helper"

class XPostTest < ActiveSupport::TestCase
  test "normalizes twitter.com to x.com and strips query params" do
    assert_equal "https://x.com/jane/status/123", XPost.normalize_url("https://twitter.com/jane/status/123?s=20")
  end

  test "find_or_create_from_url creates a post and applies oembed data" do
    data = { "html" => "<blockquote>hi</blockquote>", "author_name" => "Jane", "author_url" => "https://x.com/jane" }

    x_post = stub_oembed_fetch(data) do
      XPost.find_or_create_from_url("https://twitter.com/jane/status/123?s=20")
    end

    assert x_post.persisted?
    assert_equal "https://x.com/jane/status/123", x_post.url
    assert_equal data["html"], x_post.embed_html
    assert_equal "Jane", x_post.author_name
    assert_equal "jane", x_post.author_username
  end

  test "find_or_create_from_url returns the existing record for a duplicate url" do
    existing = XPost.create!(url: "https://x.com/jane/status/123")

    found = XPost.find_or_create_from_url("https://twitter.com/jane/status/123")

    assert_equal existing, found
    assert_equal 1, XPost.count
  end

  test "oembed_endpoint builds the publish.twitter.com oembed url" do
    x_post = XPost.new(url: "https://x.com/jane/status/123")

    assert_equal "https://publish.twitter.com/oembed?url=https%3A%2F%2Fx.com%2Fjane%2Fstatus%2F123&omit_script=true", x_post.oembed_endpoint
  end

  test "attachable partial paths" do
    x_post = XPost.new

    assert_equal "x_posts/x_post", x_post.to_attachable_partial_path
    assert_equal "x_posts/x_post", x_post.to_trix_content_attachment_partial_path
  end

  private

  def stub_oembed_fetch(data)
    original_fetch = OembedFetcher.method(:fetch)
    OembedFetcher.define_singleton_method(:fetch) { |*| data }
    yield
  ensure
    OembedFetcher.define_singleton_method(:fetch, original_fetch)
  end
end
