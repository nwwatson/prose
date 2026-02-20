require "test_helper"

class Mcp::MarkdownConverterTest < ActiveSupport::TestCase
  test "converts headings" do
    html = Mcp::MarkdownConverter.to_html("# Hello World")
    assert_includes html, "<h1>"
    assert_includes html, "Hello World"
  end

  test "converts bold and italic" do
    html = Mcp::MarkdownConverter.to_html("**bold** and *italic*")
    assert_includes html, "<strong>bold</strong>"
    assert_includes html, "<em>italic</em>"
  end

  test "converts GFM tables" do
    markdown = <<~MD
      | Name | Value |
      |------|-------|
      | foo  | bar   |
    MD

    html = Mcp::MarkdownConverter.to_html(markdown)
    assert_includes html, "<table>"
    assert_includes html, "<td>foo</td>"
  end

  test "converts code blocks" do
    markdown = "```ruby\nputs 'hello'\n```"
    html = Mcp::MarkdownConverter.to_html(markdown)
    assert_includes html, "<code"
    assert_includes html, "puts"
  end

  test "converts task lists" do
    markdown = "- [x] Done\n- [ ] Todo"
    html = Mcp::MarkdownConverter.to_html(markdown)
    assert_includes html, "type=\"checkbox\""
  end

  test "handles blank input" do
    assert_equal "", Mcp::MarkdownConverter.to_html(nil)
    assert_equal "", Mcp::MarkdownConverter.to_html("")
    assert_equal "", Mcp::MarkdownConverter.to_html("   ")
  end

  test "converts links" do
    html = Mcp::MarkdownConverter.to_html("[Click here](https://example.com)")
    assert_includes html, '<a href="https://example.com">'
  end

  test "converts images" do
    html = Mcp::MarkdownConverter.to_html("![Alt text](/image.jpg)")
    assert_includes html, '<img src="/image.jpg"'
    assert_includes html, 'alt="Alt text"'
  end
end
