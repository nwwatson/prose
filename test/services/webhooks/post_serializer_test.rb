require "test_helper"

class Webhooks::PostSerializerTest < ActiveSupport::TestCase
  test "post_url builds the canonical post URL on the configured host" do
    post = posts(:published_post)

    assert_equal "http://example.com/posts/published-post", Webhooks::PostSerializer.post_url(post)
  end

  test "payload url matches post_url" do
    post = posts(:published_post)

    assert_equal "http://example.com/posts/published-post", Webhooks::PostSerializer.call(post)[:url]
  end
end
