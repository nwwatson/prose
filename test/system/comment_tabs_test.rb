require "application_system_test_case"

class CommentTabsTest < ApplicationSystemTestCase
  ACTIVE = "comment-form__tab--active"

  setup do
    sign_in_admin
    visit post_path(slug: posts(:published_post).slug)
  end

  test "only the selected tab is marked and styled active in light and dark themes" do
    [ false, true ].each do |dark|
      execute_script("document.documentElement.classList.toggle('dark', #{dark})")

      within ".comment-form__tabs" do
        click_button I18n.t("comments.form.preview")
      end
      assert_active_tab :preview, :write

      within ".comment-form__tabs" do
        click_button I18n.t("comments.form.write")
      end
      assert_active_tab :write, :preview
    end
  end

  test "preview shows the rendered markdown and write brings the textarea back" do
    assert_no_selector ".comment-form__preview"
    find(".comment-form__textarea").fill_in with: "Some **bold** text"

    within(".comment-form__tabs") { click_button I18n.t("comments.form.preview") }

    assert_selector ".comment-form__preview strong", text: "bold"
    assert_no_selector ".comment-form__textarea"

    within(".comment-form__tabs") { click_button I18n.t("comments.form.write") }

    assert_selector ".comment-form__textarea"
    assert_no_selector ".comment-form__preview"
  end

  private

  def assert_active_tab(active, inactive)
    active_button = find_button(I18n.t("comments.form.#{active}"))
    inactive_button = find_button(I18n.t("comments.form.#{inactive}"))

    assert_selector ".#{ACTIVE}", count: 1
    assert_selector ".#{ACTIVE}", text: I18n.t("comments.form.#{active}")
    assert_not_equal border_color(active_button), border_color(inactive_button)
    assert_equal "rgba(0, 0, 0, 0)", border_color(inactive_button)
  end

  # The underline has no CSS transition, so it can be read immediately.
  def border_color(element)
    evaluate_script("getComputedStyle(arguments[0]).borderBottomColor", element)
  end
end
