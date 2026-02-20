require "test_helper"

class Mcp::PostSerializerTest < ActiveSupport::TestCase
  test "serializes post without content" do
    post = posts(:published_post)
    result = Mcp::PostSerializer.call(post)

    assert_equal post.id, result[:id]
    assert_equal post.title, result[:title]
    assert_equal post.slug, result[:slug]
    assert_equal "published", result[:status]
    assert_equal post.featured, result[:featured]
    assert_not_nil result[:published_at]
    assert_not_nil result[:created_at]
    assert_nil result[:content_html]
    assert_nil result[:content_plain]
  end

  test "serializes post with content" do
    post = posts(:published_post)
    result = Mcp::PostSerializer.call(post, include_content: true)

    assert_equal post.id, result[:id]
    assert result.key?(:content_html)
    assert result.key?(:content_plain)
  end

  test "serializes post with category and tags" do
    post = posts(:published_post)
    result = Mcp::PostSerializer.call(post)

    assert_equal "Technology", result[:category]
    assert_instance_of Array, result[:tags]
  end

  test "serializes post with nil optional fields" do
    post = posts(:draft_post)
    result = Mcp::PostSerializer.call(post)

    assert_nil result[:published_at]
    assert_nil result[:scheduled_at]
    assert_nil result[:subtitle]
    assert_nil result[:category]
  end

  test "includes author name" do
    post = posts(:published_post)
    result = Mcp::PostSerializer.call(post)

    assert_not_nil result[:author]
  end
end
