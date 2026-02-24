require "test_helper"

class TocExtractorTest < ActiveSupport::TestCase
  test "extracts h2 h3 h4 headings" do
    html = "<h2>Introduction</h2><p>text</p><h3>Details</h3><p>more</p><h4>Sub-details</h4>"
    toc = TocExtractor.new(html)

    assert_equal 3, toc.headings.size
    assert_equal 2, toc.headings[0].level
    assert_equal "Introduction", toc.headings[0].text
    assert_equal 3, toc.headings[1].level
    assert_equal 4, toc.headings[2].level
  end

  test "ignores h1 h5 h6 headings" do
    html = "<h1>Title</h1><h2>One</h2><h5>Five</h5><h2>Two</h2><h6>Six</h6><h2>Three</h2>"
    toc = TocExtractor.new(html)

    assert_equal 3, toc.headings.size
    assert toc.headings.all? { |h| h.level == 2 }
  end

  test "generates slugified ids" do
    html = "<h2>Hello World</h2><h2>Another Section</h2><h2>Third One</h2>"
    toc = TocExtractor.new(html)

    assert_equal "hello-world", toc.headings[0].id
    assert_equal "another-section", toc.headings[1].id
    assert_equal "third-one", toc.headings[2].id
  end

  test "handles duplicate heading text" do
    html = "<h2>Summary</h2><h2>Summary</h2><h2>Summary</h2>"
    toc = TocExtractor.new(html)

    assert_equal "summary", toc.headings[0].id
    assert_equal "summary-2", toc.headings[1].id
    assert_equal "summary-3", toc.headings[2].id
  end

  test "strips special characters from ids" do
    html = "<h2>What's New?</h2><h2>C++ & Rust</h2><h2>100% Complete</h2>"
    toc = TocExtractor.new(html)

    assert_equal "whats-new", toc.headings[0].id
    assert_equal "c-rust", toc.headings[1].id
    assert_equal "100-complete", toc.headings[2].id
  end

  test "has_toc? returns true with 3 or more headings" do
    html = "<h2>One</h2><h2>Two</h2><h2>Three</h2>"
    assert TocExtractor.new(html).has_toc?
  end

  test "has_toc? returns false with fewer than 3 headings" do
    html = "<h2>One</h2><h2>Two</h2>"
    refute TocExtractor.new(html).has_toc?
  end

  test "has_toc? returns false for empty content" do
    refute TocExtractor.new("").has_toc?
    refute TocExtractor.new(nil).has_toc?
  end

  test "content_with_anchors injects id attributes" do
    html = "<h2>First</h2><p>text</p><h2>Second</h2><p>more</p><h2>Third</h2>"
    result = TocExtractor.new(html).content_with_anchors

    assert_includes result, 'id="first"'
    assert_includes result, 'id="second"'
    assert_includes result, 'id="third"'
  end

  test "content_with_anchors preserves existing content" do
    html = "<h2>Heading</h2><p>Some paragraph text</p><h2>Another</h2><ul><li>item</li></ul><h2>Last</h2>"
    result = TocExtractor.new(html).content_with_anchors

    assert_includes result, "<p>Some paragraph text</p>"
    assert_includes result, "<li>item</li>"
  end

  test "content_with_anchors returns original html when fewer than 3 headings" do
    html = "<h2>Only One</h2><p>text</p>"
    assert_equal html, TocExtractor.new(html).content_with_anchors
  end

  test "handles heading with only special characters" do
    html = "<h2>???</h2><h2>!!!</h2><h2>@@@</h2>"
    toc = TocExtractor.new(html)

    assert_equal "heading", toc.headings[0].id
    assert_equal "heading-2", toc.headings[1].id
    assert_equal "heading-3", toc.headings[2].id
  end
end
