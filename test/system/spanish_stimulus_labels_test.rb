require "application_system_test_case"

# Labels a Stimulus controller writes come from data-*-value attributes, so a
# Spanish site must stay Spanish after the controller changes them.
class SpanishStimulusLabelsTest < ApplicationSystemTestCase
  TOGGLE = "[data-action='click->post-preview#toggle']"

  test "the preview toggle keeps Spanish labels and icons" do
    sign_in_admin
    SiteSetting.current.update!(locale: "es")
    visit edit_admin_post_path(posts(:published_post))

    assert_toggle_shows "shared.preview"

    find(TOGGLE).click
    assert_toggle_shows "shared.edit"

    find(TOGGLE).click
    assert_toggle_shows "shared.preview"
  end

  test "the autosave status is written in Spanish" do
    sign_in_admin
    SiteSetting.current.update!(locale: "es")
    visit edit_admin_post_path(posts(:published_post))

    fill_in "post_title", with: "Un título nuevo"

    assert_selector "[data-autosave-target='status']", text: spanish("layouts.editor.autosave.unsaved")
    assert_selector "[data-autosave-target='status']", text: spanish("layouts.editor.autosave.saved"), wait: 10
  end

  test "the comment preview's empty message is Spanish" do
    sign_in_admin
    SiteSetting.current.update!(locale: "es")
    visit post_path(slug: posts(:published_post).slug)

    within(".comment-form__tabs") { click_button spanish("comments.form.preview") }

    assert_selector ".comment-form__preview", text: spanish("comments.form.nothing_to_preview")
  end

  private
    # Visible text and icon only: Capybara's button locator also matches the
    # hidden pair's text.
    def assert_toggle_shows(key)
      assert_selector TOGGLE, exact_text: spanish(key)
      assert_selector "#{TOGGLE} svg", count: 1
    end

    def spanish(key)
      I18n.t(key, locale: :es)
    end
end
