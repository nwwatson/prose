require "test_helper"

class MarkdownRendererTest < ActiveSupport::TestCase
  test "converts markdown to HTML" do
    html = MarkdownRenderer.to_html("**bold**")
    assert_includes html, "<strong>bold</strong>"
  end

  test "returns empty string for nil input" do
    assert_equal "", MarkdownRenderer.to_html(nil)
  end

  test "returns empty string for blank input" do
    assert_equal "", MarkdownRenderer.to_html("")
    assert_equal "", MarkdownRenderer.to_html("   ")
  end

  test "does not allow raw HTML passthrough" do
    html = MarkdownRenderer.to_html('<script>alert("xss")</script>')
    assert_not_includes html, "<script>"
  end

  test "autolinks URLs" do
    html = MarkdownRenderer.to_html("Visit https://example.com")
    assert_includes html, '<a href="https://example.com">'
  end

  test "renders strikethrough" do
    html = MarkdownRenderer.to_html("~~removed~~")
    assert_includes html, "<del>removed</del>"
  end

  test "enables hardbreaks" do
    html = MarkdownRenderer.to_html("line one\nline two")
    assert_includes html, "<br"
  end
end
