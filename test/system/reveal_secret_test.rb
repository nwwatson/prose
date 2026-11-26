require "application_system_test_case"

class RevealSecretTest < ApplicationSystemTestCase
  test "the copy button puts a newly created API token on the clipboard" do
    sign_in_admin
    visit admin_api_tokens_path
    fill_in "name", with: "Copy me"
    click_button I18n.t("admin.api_tokens.index.generate_token")

    token = find("[data-clipboard-target='source']").text
    assert token.start_with?(ApiToken::TOKEN_PREFIX)

    execute_script <<~JS
      window.copied = null
      Object.defineProperty(navigator, "clipboard", {
        configurable: true,
        value: { writeText: (text) => { window.copied = text; return Promise.resolve() } }
      })
    JS
    click_button I18n.t("admin.api_tokens.index.copy")

    page.document.synchronize { raise Capybara::ElementNotFound unless evaluate_script("window.copied") }
    assert_equal token, evaluate_script("window.copied")
  end
end
