require "test_helper"

class Mcp::Tools::CreatePostTest < ActiveSupport::TestCase
  test "creates a draft post with markdown content" do
    assert_difference "Post.count", 1 do
      result = Mcp::Tools::CreatePost.call(
        server_context: { user: users(:admin) },
        title: "My New Post",
        content: "# Hello\n\nThis is **bold** text.",
        subtitle: "A subtitle",
        category: "Technology",
        tags: %w[Ruby Rails]
      )

      parsed = JSON.parse(result.content.first[:text])
      assert_equal "My New Post", parsed["title"]
      assert_equal "draft", parsed["status"]
      assert_equal "Technology", parsed["category"]
      assert_includes parsed["content_html"], "<h1>"
      assert_includes parsed["content_html"], "<strong>bold</strong>"
      assert_equal %w[Rails Ruby], parsed["tags"].sort
    end
  end

  test "assigns the requesting user as author" do
    result = Mcp::Tools::CreatePost.call(server_context: { user: users(:admin) }, title: "Minimal Post")

    parsed = JSON.parse(result.content.first[:text])
    post_record = Post.find(parsed["id"])
    assert_equal users(:admin), post_record.user
  end

  test "finds category by slug" do
    result = Mcp::Tools::CreatePost.call(server_context: { user: users(:admin) }, title: "Slugged", category: "design")

    parsed = JSON.parse(result.content.first[:text])
    assert_equal "Design", parsed["category"]
  end

  test "returns error for invalid post" do
    result = Mcp::Tools::CreatePost.call(server_context: { user: users(:admin) }, title: "Invalid Post", meta_description: "x" * 200)

    assert result.error?
    parsed = JSON.parse(result.content.first[:text])
    assert parsed["error"].present?
  end
end
