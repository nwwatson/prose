require "test_helper"

class CommentMarkdownTest < ActiveSupport::TestCase
  test "renders bold text" do
    comment = Comment.new(body: "This is **bold** text")
    assert_includes comment.rendered_body, "<strong>bold</strong>"
  end

  test "renders italic text" do
    comment = Comment.new(body: "This is *italic* text")
    assert_includes comment.rendered_body, "<em>italic</em>"
  end

  test "renders inline code" do
    comment = Comment.new(body: "Use `Array#map` here")
    assert_includes comment.rendered_body, "<code>Array#map</code>"
  end

  test "renders code blocks" do
    comment = Comment.new(body: "```\ndef hello\n  puts 'hi'\nend\n```")
    assert_includes comment.rendered_body, "<pre>"
    assert_includes comment.rendered_body, "<code>"
  end

  test "renders links" do
    comment = Comment.new(body: "Visit [example](https://example.com)")
    assert_includes comment.rendered_body, '<a href="https://example.com">'
    assert_includes comment.rendered_body, "example</a>"
  end

  test "renders autolinks" do
    comment = Comment.new(body: "Check https://example.com for details")
    assert_includes comment.rendered_body, '<a href="https://example.com">'
  end

  test "renders unordered lists" do
    comment = Comment.new(body: "- item one\n- item two")
    assert_includes comment.rendered_body, "<ul>"
    assert_includes comment.rendered_body, "<li>item one</li>"
  end

  test "renders ordered lists" do
    comment = Comment.new(body: "1. first\n2. second")
    assert_includes comment.rendered_body, "<ol>"
    assert_includes comment.rendered_body, "<li>first</li>"
  end

  test "renders blockquotes" do
    comment = Comment.new(body: "> quoted text")
    assert_includes comment.rendered_body, "<blockquote>"
    assert_includes comment.rendered_body, "quoted text"
  end

  test "renders strikethrough" do
    comment = Comment.new(body: "This is ~~deleted~~ text")
    assert_includes comment.rendered_body, "<del>deleted</del>"
  end

  test "returns empty string for blank body" do
    comment = Comment.new(body: nil)
    assert_equal "", comment.rendered_body

    comment.body = ""
    assert_equal "", comment.rendered_body
  end

  test "preserves line breaks with hardbreaks" do
    comment = Comment.new(body: "line one\nline two")
    assert_includes comment.rendered_body, "<br"
  end

  test "renders paragraphs for double newlines" do
    comment = Comment.new(body: "para one\n\npara two")
    html = comment.rendered_body
    assert html.scan("<p>").length >= 2
  end
end
