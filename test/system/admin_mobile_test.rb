require "application_system_test_case"

class AdminMobileTest < ApplicationSystemTestCase
  setup do
    sign_in_admin
  end

  test "mobile sidebar opens and closes via hamburger" do
    with_mobile_viewport do
      visit admin_root_path

      # Open sidebar via hamburger
      find("button[data-action='click->admin-sidebar#open']").click
      assert_selector "[data-admin-sidebar-target='sidebar'].translate-x-0"

      # Close via backdrop
      find("[data-admin-sidebar-target='backdrop']").click
      assert_selector "[data-admin-sidebar-target='sidebar'].-translate-x-full"
    end
  end

  test "mobile sidebar closes on navigation" do
    with_mobile_viewport do
      visit admin_root_path

      find("button[data-action='click->admin-sidebar#open']").click
      assert_selector "[data-admin-sidebar-target='sidebar'].translate-x-0"

      # Click a nav link inside the mobile sidebar
      within "[data-admin-sidebar-target='sidebar']" do
        click_link I18n.t("layouts.admin.all_posts")
      end

      # Should navigate to posts
      assert_current_path admin_posts_path
    end
  end

  test "posts index shows card layout on mobile" do
    with_mobile_viewport do
      visit admin_posts_path

      assert_text I18n.t("admin.posts.index.title")
      # Mobile cards should be present
      assert_selector "[data-testid='mobile-post-cards']"
    end
  end

  test "posts index shows table layout on desktop" do
    visit admin_posts_path

    assert_text I18n.t("admin.posts.index.title")
    assert_selector "[data-testid='desktop-post-table'] table"
  end

  test "dashboard renders without horizontal overflow on mobile" do
    with_mobile_viewport do
      visit admin_root_path

      assert_text I18n.t("admin.dashboard.show.title")
      assert_selector ".bg-white.shadow.rounded-lg"
    end
  end

  test "subscribers index renders on mobile" do
    with_mobile_viewport do
      visit admin_subscribers_path

      assert_text I18n.t("admin.subscribers.index.title")
    end
  end

  test "newsletters index renders on mobile" do
    with_mobile_viewport do
      visit admin_newsletters_path

      assert_text I18n.t("admin.newsletters.index.title")
    end
  end

  test "tablet viewport shows hamburger menu" do
    with_tablet_viewport do
      visit admin_root_path

      assert_text I18n.t("admin.dashboard.show.title")
      assert_selector "button[data-action='click->admin-sidebar#open']"
    end
  end

  test "comments page renders on mobile" do
    with_mobile_viewport do
      visit admin_comments_path

      assert_text I18n.t("admin.comments.index.title")
    end
  end

  test "traffic page renders on mobile" do
    with_mobile_viewport do
      visit admin_traffic_path

      assert_text I18n.t("admin.traffic.show.title")
    end
  end

  test "growth page renders on mobile" do
    with_mobile_viewport do
      visit admin_growth_path

      assert_text I18n.t("admin.growth.show.title")
    end
  end
end
