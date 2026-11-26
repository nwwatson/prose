require "application_system_test_case"

# Drives the shared drawer shell (layouts/editor/_drawer) in each editor that renders it.
class EditorDrawerTest < ApplicationSystemTestCase
  PANEL = "[data-editor-drawer-target='panel']"

  setup do
    sign_in_admin
    page.execute_script("localStorage.removeItem('prose:editor-drawer-pinned')")
  end

  test "post editor drawer opens, switches tabs, pins and closes on Escape" do
    visit edit_admin_post_path(posts(:published_post))

    open_drawer
    assert_tab_shown "settings"

    find("button[data-tab='versions']").click
    assert_tab_shown "versions"
    assert_selector "button[data-tab='versions'].border-blue-500"
    assert_selector "button[data-tab='settings'].border-transparent"

    toggle_pin
    send_escape
    assert_drawer_closed
  end

  test "newsletter editor drawer opens, pins and closes on Escape" do
    visit edit_admin_newsletter_path(newsletters(:draft_newsletter))

    open_drawer
    assert_tab_shown "settings"
    assert_selector "button[data-tab='settings'].border-blue-500"

    toggle_pin
    send_escape
    assert_drawer_closed
  end

  test "page editor drawer opens, pins and closes on Escape" do
    visit edit_admin_page_path(pages(:published_page))

    open_drawer
    assert_tab_shown "settings"

    toggle_pin
    send_escape
    assert_drawer_closed
  end

  private
    def open_drawer
      assert_selector "#{PANEL}.translate-x-full", visible: :all
      find("button[data-action='click->editor-drawer#toggle']").click
      assert_no_selector "#{PANEL}.translate-x-full", visible: :all
    end

    def assert_tab_shown(tab)
      assert_selector "#{PANEL} [data-editor-drawer-target='tabContent'][data-tab='#{tab}']:not(.hidden)", visible: :all
    end

    def toggle_pin
      within(PANEL) { find("button[data-action='click->editor-drawer#togglePin']").click }
      assert_selector "[data-editor-drawer-target='pinIcon'].text-blue-600", visible: :all
      within(PANEL) { find("button[data-action='click->editor-drawer#togglePin']").click }
      assert_selector "[data-editor-drawer-target='pinIcon'].text-gray-400", visible: :all
    end

    def send_escape
      find("body").send_keys(:escape)
    end

    def assert_drawer_closed
      assert_selector "#{PANEL}.translate-x-full", visible: :all
    end
end
