require "test_helper"

class StructuredDataHelperTest < ActionView::TestCase
  include StructuredDataHelper
  # json_ld_breadcrumb_list builds its items from BreadcrumbsHelper#breadcrumb_items.
  include BreadcrumbsHelper
  # json_ld_for_post resolves the post image via ImageOptimizationHelper.
  include ImageOptimizationHelper

  setup do
    @post = posts(:published_post)
    @category = categories(:technology)
  end

  test "json_ld_tag renders script with correct type" do
    result = json_ld_tag({ "@type": "Organization", name: "Test" })
    assert_includes result, "application/ld+json"
    assert_includes result, "Organization"
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

  test "json_ld_breadcrumb_list omits item url for the current page" do
    post = posts(:draft_post)
    post.category = nil
    data = JSON.parse(Nokogiri::HTML5.fragment(json_ld_breadcrumb_list(post)).text)

    refute data["itemListElement"].last.key?("item")
  end

  test "json_ld_for_post includes article fields" do
    data = JSON.parse(Nokogiri::HTML5.fragment(json_ld_for_post(@post)).text)

    assert_equal "Article", data["@type"]
    assert_equal @post.title, data["headline"]
    assert_equal @post.seo_description, data["description"]
    assert_equal @post.user.identity.name, data.dig("author", "name")
    assert_equal @post.reading_time_minutes * 238, data["wordCount"]
  end

  test "json_ld_for_post omits image when no featured image is attached" do
    refute @post.featured_image.attached?
    data = JSON.parse(Nokogiri::HTML5.fragment(json_ld_for_post(@post)).text)

    refute data.key?("image")
  end

  test "json_ld_for_author includes name and url" do
    identity = identities(:admin_identity)
    data = JSON.parse(Nokogiri::HTML5.fragment(json_ld_for_author(identity)).text)

    assert_equal "Person", data["@type"]
    assert_equal identity.name, data["name"]
    assert_equal author_url(identity, handle: identity.handle), data["url"]
  end
end
