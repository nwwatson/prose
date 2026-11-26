require "test_helper"

class EditorDrawerPartialsTest < ActionView::TestCase
  test "drawer renders the panel target, pin button and body" do
    render(layout: "layouts/editor/drawer", locals: { title: "Editor Panel", data: { controller: "ai-chat" } }) { "Tabs here" }

    assert_select "div[data-editor-drawer-target=panel][data-controller=ai-chat].translate-x-full" do
      assert_select "span", text: "Editor Panel"
      assert_select "button[data-action='click->editor-drawer#togglePin'][title=?]", I18n.t("layouts.editor.pin_panel") do
        assert_select "svg[data-editor-drawer-target=pinIcon]"
      end
    end
    assert_includes rendered, "Tabs here"
  end

  test "drawer renders header actions before the pin button" do
    render(layout: "layouts/editor/drawer", locals: { title: "Editor Panel", header_actions: tag.button("Clear", id: "clear") }) { "" }

    assert_operator rendered.index('id="clear"'), :<, rendered.index("togglePin")
  end

  test "drawer translates the pin button title" do
    I18n.with_locale(:es) do
      render(layout: "layouts/editor/drawer", locals: { title: "Panel" }) { "" }
    end

    assert_select "button[title='Fijar panel']"
  end

  test "drawer tab renders the tab button target" do
    render "layouts/editor/drawer_tab", tab: "versions", label: "Versions"

    assert_select "button[data-editor-drawer-target=tabButton][data-tab=versions][data-action='click->editor-drawer#switchTab'].border-transparent", text: "Versions"
  end

  test "an active drawer tab starts highlighted" do
    render "layouts/editor/drawer_tab", tab: "settings", label: "Settings", active: true

    assert_select "button.border-blue-500.text-blue-600:not(.border-transparent)"
  end
end
