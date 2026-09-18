require "test_helper"

class PublicNavigationTest < ActionDispatch::IntegrationTest
  test "header renders navigation items in order" do
    get root_path
    assert_response :success
    assert_select "nav.masthead__nav a.masthead__nav-link", count: 2 do |links|
      assert_equal [ "Home", "About Us" ], links.map(&:text)
      assert_equal [ "/", "/about-us" ], links.map { |a| a["href"] }
    end
  end

  test "current page link is marked with aria-current" do
    get page_path("about-us")
    assert_select "a.masthead__nav-link[aria-current=page]", text: "About Us"
    assert_select "a.masthead__nav-link[aria-current=page]", count: 1
  end

  test "header nav is omitted when there are no header items" do
    NavigationItem.header.destroy_all
    get root_path
    assert_select "nav.masthead__nav", 0
  end

  test "footer renders footer links and social icons" do
    get root_path
    assert_select "nav.site-footer__nav a.site-footer__link[href='/privacy']", text: "Privacy"
    assert_select ".site-footer__social a.site-footer__social-link[href='https://github.com/prose'][target=_blank][rel='noopener noreferrer']" do
      assert_select "svg.site-footer__social-icon"
      assert_select ".sr-only", text: "GitHub"
    end
  end

  test "links not set to open in a new tab have no target" do
    get root_path
    assert_select "a.site-footer__link[href='/privacy'][target]", 0
  end
end
