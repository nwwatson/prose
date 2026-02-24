require "test_helper"

class PageTest < ActiveSupport::TestCase
  test "valid page" do
    page = Page.new(title: "Test Page", user: users(:admin))
    assert page.valid?
  end

  test "requires title" do
    page = Page.new(user: users(:admin))
    assert_not page.valid?
    assert_includes page.errors[:title], "can't be blank"
  end

  test "defaults to draft status" do
    page = Page.new
    assert page.draft?
  end

  test "generates slug from title" do
    page = Page.new(title: "My Custom Page", user: users(:admin))
    page.valid?
    assert_equal "my-custom-page", page.slug
  end

  test "slug must be unique" do
    page = Page.new(title: "Test", slug: pages(:published_page).slug, user: users(:admin))
    assert_not page.valid?
    assert_includes page.errors[:slug], "has already been taken"
  end

  test "slug must be URL-safe" do
    page = Page.new(title: "Test", slug: "Invalid Slug!", user: users(:admin))
    assert_not page.valid?
    assert page.errors[:slug].any?
  end

  test "rejects reserved slugs" do
    Page::RESERVED_SLUGS.each do |reserved|
      page = Page.new(title: "Test", slug: reserved, user: users(:admin))
      assert_not page.valid?, "Expected slug '#{reserved}' to be rejected"
      assert_includes page.errors[:slug], "is reserved"
    end
  end

  test "meta_description limited to 160 characters" do
    page = Page.new(title: "Test", meta_description: "x" * 161, user: users(:admin))
    assert_not page.valid?
    assert page.errors[:meta_description].any?
  end

  test "to_param returns slug" do
    assert_equal "about-us", pages(:published_page).to_param
  end

  test "seo_description returns meta_description when present" do
    page = pages(:published_page)
    assert_equal "Learn more about us", page.seo_description
  end

  test "live scope returns only published pages with past published_at" do
    live = Page.live
    assert_includes live, pages(:published_page)
    assert_includes live, pages(:contact_page)
    assert_not_includes live, pages(:draft_page)
  end

  test "publish! sets status and published_at" do
    page = pages(:draft_page)
    page.publish!
    assert page.published?
    assert_not_nil page.published_at
  end

  test "revert_to_draft! clears status and published_at" do
    page = pages(:published_page)
    page.revert_to_draft!
    assert page.draft?
    assert_nil page.published_at
  end

  test "navigation scope returns published navigation pages ordered by position" do
    nav_pages = Page.navigation
    assert_includes nav_pages, pages(:published_page)
    assert_includes nav_pages, pages(:contact_page)
    assert_not_includes nav_pages, pages(:draft_page)
    assert_equal pages(:published_page), nav_pages.first
  end

  test "belongs to user" do
    assert_equal users(:admin), pages(:published_page).user
  end
end
