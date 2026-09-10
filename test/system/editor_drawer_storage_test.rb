require "application_system_test_case"

class EditorDrawerStorageTest < ApplicationSystemTestCase
  setup do
    sign_in_admin
  end

  test "editor drawer opens and pins when localStorage throws" do
    # Stub storage to throw *before* navigating, then use a Turbo visit so the
    # JS context (and the stub) survives into the editor page — the drawer's
    # connect() then runs against a throwing localStorage.
    visit admin_posts_path
    break_local_storage!

    page.execute_script("window.Turbo.visit(#{admin_edit_post_path.to_json})")
    assert_selector "[data-editor-drawer-target='panel']", visible: :all

    panel = find("[data-editor-drawer-target='panel']", visible: :all)
    assert panel[:class].include?("translate-x-full"), "drawer should start closed"

    find("button[data-action='click->editor-drawer#toggle']").click
    assert_no_selector "[data-editor-drawer-target='panel'].translate-x-full", visible: :all

    find("button[data-action='click->editor-drawer#togglePin']").click
    assert_selector "[data-editor-drawer-target='pinIcon'].text-blue-600", visible: :all

    assert_no_storage_errors
  end

  test "theme toggle still flips the theme when localStorage throws" do
    visit root_path
    break_local_storage!

    page.execute_script("window.Turbo.visit(#{root_path.to_json})")
    assert_selector "[data-controller~='theme-toggle']"

    was_dark = page.evaluate_script("document.documentElement.classList.contains('dark')")
    find("[data-action*='theme-toggle#toggle']").click

    assert_equal !was_dark, page.evaluate_script("document.documentElement.classList.contains('dark')")

    assert_no_storage_errors
  end

  private
    def admin_edit_post_path
      edit_admin_post_path(posts(:published_post))
    end

    def break_local_storage!
      drain_browser_logs
      page.execute_script(<<~JS)
        (function() {
          const boom = () => { throw new DOMException("denied", "SecurityError") }
          const stub = { getItem: boom, setItem: boom, removeItem: boom, clear: boom, key: boom, length: 0 }
          Object.defineProperty(window, "localStorage", { configurable: true, get: () => stub })
        })()
      JS
    end

    def drain_browser_logs
      page.driver.browser.logs.get(:browser)
    end

    # Guarded storage should swallow the SecurityError rather than let it
    # surface as an uncaught exception in the page.
    def assert_no_storage_errors
      messages = drain_browser_logs.map(&:message).grep(/SecurityError|denied/)
      assert_empty messages, "expected no storage errors in the browser console"
    end
end
