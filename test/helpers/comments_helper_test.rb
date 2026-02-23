require "test_helper"

class CommentsHelperTest < ActionView::TestCase
  include CommentsHelper

  test "allows safe tags" do
    html = "<p>Hello <strong>world</strong> and <em>italic</em></p>"
    result = sanitize_markdown(html)
    assert_includes result, "<p>"
    assert_includes result, "<strong>"
    assert_includes result, "<em>"
  end

  test "allows links with href" do
    html = '<a href="https://example.com">link</a>'
    result = sanitize_markdown(html)
    assert_includes result, 'href="https://example.com"'
    assert_includes result, 'rel="nofollow noopener"'
    assert_includes result, 'target="_blank"'
  end

  test "allows code and pre tags" do
    html = "<pre><code>puts 'hello'</code></pre>"
    result = sanitize_markdown(html)
    assert_includes result, "<pre>"
    assert_includes result, "<code>"
  end

  test "allows list tags" do
    html = "<ul><li>one</li><li>two</li></ul>"
    result = sanitize_markdown(html)
    assert_includes result, "<ul>"
    assert_includes result, "<li>"
  end

  test "allows blockquote" do
    html = "<blockquote>quoted</blockquote>"
    result = sanitize_markdown(html)
    assert_includes result, "<blockquote>"
  end

  test "strips script tags" do
    html = '<p>Hello</p><script>alert("xss")</script>'
    result = sanitize_markdown(html)
    assert_not_includes result, "<script>"
  end

  test "strips event handler attributes" do
    html = '<p onmouseover="alert(1)">text</p>'
    result = sanitize_markdown(html)
    assert_not_includes result, "onmouseover"
  end

  test "strips style tags" do
    html = "<style>body{display:none}</style><p>text</p>"
    result = sanitize_markdown(html)
    assert_not_includes result, "<style>"
  end

  test "strips img tags" do
    html = '<img src="x" onerror="alert(1)">'
    result = sanitize_markdown(html)
    assert_not_includes result, "<img"
  end

  test "strips iframe tags" do
    html = '<iframe src="https://evil.com"></iframe>'
    result = sanitize_markdown(html)
    assert_not_includes result, "<iframe"
  end

  test "strips javascript: URIs from links" do
    html = '<a href="javascript:alert(1)">click</a>'
    result = sanitize_markdown(html)
    assert_not_includes result, "javascript:"
  end

  test "strips disallowed tags but keeps content" do
    html = "<div><span>kept text</span></div>"
    result = sanitize_markdown(html)
    assert_not_includes result, "<div>"
    assert_not_includes result, "<span>"
    assert_includes result, "kept text"
  end
end
