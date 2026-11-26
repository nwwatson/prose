require "application_system_test_case"

class HandleCheckTest < ApplicationSystemTestCase
  test "typing a handle reports whether it is available" do
    taken = identities(:subscriber_identity).handle
    visit root_path
    mount_handle_form

    fill_in "handle", with: "brandnewhandle"
    assert_selector "#handle_availability", text: I18n.t("handles.availability.available")

    fill_in "handle", with: taken
    assert_selector "#handle_availability", text: I18n.t("handles.availability.taken")
  end

  private
    # No page renders the form on first load (it only replaces #handle_form over a
    # Turbo Stream), so insert the partial into a public page.
    def mount_handle_form
      html = ApplicationController.render(partial: "handles/form", locals: { identity: Identity.new })
      execute_script("document.body.insertAdjacentHTML('afterbegin', arguments[0])", html)
    end
end
