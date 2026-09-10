require "test_helper"

class BreadcrumbsHelperTest < ActionView::TestCase
  include BreadcrumbsHelper

  setup do
    @post = posts(:published_post)
    @category = categories(:technology)
  end

  test "breadcrumb items with category" do
    @post.category = @category
    items = breadcrumb_items(@post)

    assert_equal [ "Home", @category.name, @post.title ], items.map { |i| i[:name] }
    assert_equal root_path, items.first[:path]
    assert_equal root_url, items.first[:url]
    assert_nil items.last[:path]
    assert_nil items.last[:url]
  end

  test "breadcrumb items without category" do
    post = posts(:draft_post)
    post.category = nil

    assert_equal [ "Home", post.title ], breadcrumb_items(post).map { |i| i[:name] }
  end

  test "breadcrumb navigation with category" do
    @post.category = @category
    result = breadcrumb_navigation(@post)

    assert_includes result, "Home"
    assert_includes result, @category.name
    assert_includes result, @post.title
    assert_includes result, ">"
    assert_includes result, 'href="/"'
  end

  test "breadcrumb navigation without category" do
    post = posts(:draft_post)
    post.category = nil
    result = breadcrumb_navigation(post)

    assert_includes result, "Home"
    assert_includes result, post.title
    assert_includes result, ">"
    # Should not include category link
    refute_includes result, "categories"
  end

  test "breadcrumb navigation renders the current page as a span, not a link" do
    post = posts(:draft_post)
    post.category = nil

    assert_includes breadcrumb_navigation(post), %(<span class="text-gray-600 dark:text-gray-400">#{post.title}</span>)
  end

  test "breadcrumb navigation escapes html in titles" do
    post = posts(:published_post)
    post.title = "Test <script>alert('xss')</script>"
    result = breadcrumb_navigation(post)

    assert_includes result, "Home"
    refute_includes result, "<script>"
  end
end
