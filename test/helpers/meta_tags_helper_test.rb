require "test_helper"

class MetaTagsHelperTest < ActionView::TestCase
  include MetaTagsHelper

  setup do
    @user = users(:admin)
    @post = posts(:published_post)
    @category = categories(:technology)
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

  test "json_ld_breadcrumb_list with category" do
    @post.category = @category
    @post.save!
    result = json_ld_breadcrumb_list(@post)

    # Verify structure in string representation
    assert_includes result, '"BreadcrumbList"'
    assert_includes result, '"@context"'
    assert_includes result, "https://schema.org"
    assert_includes result, '"Home"'
    assert_includes result, @category.name
    assert_includes result, @post.title
  end

  test "json_ld_breadcrumb_list positions correct with category" do
    @post.category = @category
    @post.save!
    result = json_ld_breadcrumb_list(@post)

    # Should have 3 items: Home, Category, Post
    # JSON format uses no spaces after colons
    assert_includes result, '"position":1'
    assert_includes result, '"position":2'
    assert_includes result, '"position":3'
  end

  test "json_ld_breadcrumb_list positions correct without category" do
    post = posts(:draft_post)
    post.category = nil
    post.save!
    result = json_ld_breadcrumb_list(post)

    # Should have 2 items: Home, Post
    assert_includes result, '"position":1'
    assert_includes result, '"position":2'
    refute_includes result, '"position":3'
  end

  test "json_ld_breadcrumb_list includes home url" do
    @post.category = @category
    result = json_ld_breadcrumb_list(@post)

    assert_includes result, root_url
  end

  test "json_ld_breadcrumb_list includes category url" do
    @post.category = @category
    @post.save!
    result = json_ld_breadcrumb_list(@post)

    category_url_str = category_url(@category, slug: @category.slug)
    assert_includes result, category_url_str
  end

  test "json_ld_breadcrumb_list post item structure" do
    @post.category = @category
    result = json_ld_breadcrumb_list(@post)

    # The post breadcrumb item should be a ListItem
    assert_includes result, '"@type":"ListItem"'
    assert_includes result, @post.title
  end

  test "json_ld_tag renders script with correct type" do
    result = json_ld_tag({ "@type": "Organization", name: "Test" })
    assert_includes result, "application/ld+json"
    assert_includes result, "Organization"
  end

  test "breadcrumb navigation escapes html in titles" do
    post = posts(:published_post)
    post.title = "Test <script>alert('xss')</script>"
    result = breadcrumb_navigation(post)

    assert_includes result, "Home"
    refute_includes result, "<script>"
  end
end
