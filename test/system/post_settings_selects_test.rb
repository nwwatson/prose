require "application_system_test_case"

# Covers the keyboard behavior `tag_select` and `custom_select` now share via
# `lib/listbox.js`, plus the two-stage Escape between an open dropdown and the
# editor drawer (which no longer probes either controller's DOM).
class PostSettingsSelectsTest < ApplicationSystemTestCase
  setup do
    sign_in_admin
    @post = posts(:draft_post) # no tags, no category
  end

  test "Enter with no highlighted option creates a tag and adds a pill" do
    open_settings_tab

    tag_search_input.send_keys("Hotwire")
    assert_selector "[data-tag-select-target='createLabel']", text: "Hotwire"

    tag_search_input.send_keys(:enter)

    assert_selector "[data-tag-select-target='pills'] [data-pill-name]", text: "Hotwire"
    assert Tag.exists?(name: "Hotwire")
  end

  test "arrow keys and Enter select an existing tag" do
    open_settings_tab

    tag_search_input.send_keys("rub")
    tag_search_input.send_keys(:arrow_down, :enter)

    assert_selector "[data-tag-select-target='pills'] [data-pill-name]", text: "Ruby"
    assert_selector "[data-tag-select-target='hiddenInputs'] input[data-tag-id='#{tags(:ruby).id}']", visible: :all
  end

  test "Backspace on an empty search input removes the last pill" do
    open_settings_tab

    tag_search_input.send_keys("rub", :arrow_down, :enter)
    assert_selector "[data-tag-select-target='pills'] [data-pill-name]", text: "Ruby"

    tag_search_input.send_keys(:backspace)

    assert_no_selector "[data-tag-select-target='pills'] [data-pill-name]"
  end

  test "arrow keys and Enter pick a category in the custom select" do
    open_settings_tab

    within category_select do
      assert_selector "[data-custom-select-target='triggerText']", text: I18n.t("shared.no_category")
      find("[data-custom-select-target='trigger']").click
      assert_selector "[data-custom-select-target='dropdown'].opacity-100", visible: :all

      find("[data-custom-select-target='trigger']").send_keys(:arrow_down, :enter)

      assert_selector "[data-custom-select-target='triggerText']", text: categories(:technology).name
      assert_equal categories(:technology).id.to_s, find("select", visible: :all).value
    end
  end

  test "Escape closes an open custom select without closing the drawer" do
    open_settings_tab

    within category_select do
      find("[data-custom-select-target='trigger']").click
      assert_selector "[data-custom-select-target='dropdown'].opacity-100", visible: :all

      find("[data-custom-select-target='trigger']").send_keys(:escape)

      assert_selector "[data-custom-select-target='dropdown'].opacity-0", visible: :all
    end
    assert_drawer_open

    within(category_select) { find("[data-custom-select-target='trigger']").send_keys(:escape) }

    assert_drawer_closed
  end

  test "Escape closes an open tag select without closing the drawer" do
    open_settings_tab

    tag_search_input.click
    assert_selector "[data-tag-select-target='dropdown']:not(.hidden)", visible: :all

    tag_search_input.send_keys(:escape)

    assert_selector "[data-tag-select-target='dropdown'].hidden", visible: :all
    assert_drawer_open

    find("body").send_keys(:escape)

    assert_drawer_closed
  end

  private
    def open_settings_tab
      visit edit_admin_post_path(@post)
      find("button[data-action='click->editor-drawer#toggle']").click
      find("[data-editor-drawer-target='tabButton'][data-tab='settings']").click
      assert_selector "[data-editor-drawer-target='tabContent'][data-tab='settings']:not(.hidden)"
    end

    def tag_search_input
      find("[data-tag-select-target='searchInput']")
    end

    # Several custom selects share the settings tab, so scope by the hidden
    # <select> the controller wraps.
    def category_select
      find("select[name='post[category_id]']", visible: :all)
        .find(:xpath, "ancestor::div[@data-controller='custom-select'][1]")
    end

    def assert_drawer_open
      assert_selector "[data-editor-drawer-target='panel']:not(.translate-x-full)", visible: :all
    end

    def assert_drawer_closed
      assert_selector "[data-editor-drawer-target='panel'].translate-x-full", visible: :all
    end
end
