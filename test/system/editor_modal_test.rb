require "application_system_test_case"

# The generic `modal` controller as mounted by layouts/editor/_discard_modal,
# opened by autosave's `discard-requested` event.
class EditorModalTest < ApplicationSystemTestCase
  PANEL = "[data-editor-drawer-target='panel']"
  DIALOG = "[data-controller='modal'] [data-modal-target='dialog']"

  setup do
    sign_in_admin
    page.execute_script("localStorage.removeItem('prose:editor-drawer-pinned')")
  end

  test "Back on an empty new post opens the discard modal, and Keep editing closes it" do
    visit new_admin_post_path
    assert_selector DIALOG, visible: :hidden

    click_back
    assert_selector DIALOG, visible: true
    assert page.evaluate_script("document.body.classList.contains('overflow-hidden')")

    click_on I18n.t("layouts.editor.keep_editing")
    assert_selector DIALOG, visible: :hidden
    assert_not page.evaluate_script("document.body.classList.contains('overflow-hidden')")
  end

  test "first Escape closes the discard modal and only the next closes the drawer" do
    visit new_admin_post_path
    find("button[data-action='click->editor-drawer#toggle']").click
    assert_no_selector "#{PANEL}.translate-x-full", visible: :all

    click_back
    assert_selector DIALOG, visible: true

    find(DIALOG).send_keys(:escape)
    assert_selector DIALOG, visible: :hidden
    assert_no_selector "#{PANEL}.translate-x-full", visible: :all

    find("body").send_keys(:escape)
    assert_selector "#{PANEL}.translate-x-full", visible: :all
  end

  test "Discard leaves the editor" do
    visit new_admin_post_path

    click_back
    click_on I18n.t("layouts.editor.discard")

    assert_current_path admin_posts_path
  end

  private
    # The drawer overlay can sit above the top bar, so click through script.
    def click_back
      page.execute_script("document.querySelector(\"[data-action='click->autosave#handleBack']\").click()")
    end
end
