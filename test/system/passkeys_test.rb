require "application_system_test_case"

# Drives the real WebAuthn ceremonies against Chrome's virtual authenticator, so
# the encoding between the browser and the server is exercised end to end.
class PasskeysTest < ApplicationSystemTestCase
  setup do
    sign_in_admin

    # WebAuthn needs a host name as the relying party id, not 127.0.0.1.
    @previous_app_host = Capybara.app_host
    @previous_origins = WebAuthn.configuration.allowed_origins
    origin = "http://localhost:#{Capybara.current_session.server.port}"
    Capybara.app_host = origin
    WebAuthn.configuration.allowed_origins = [ origin ]

    @authenticator = page.driver.browser.add_virtual_authenticator(
      Selenium::WebDriver::VirtualAuthenticatorOptions.new(
        protocol: :ctap2, transport: :internal,
        resident_key: true, user_verification: true, user_verified: true
      )
    )
    sign_in_admin
  end

  teardown do
    @authenticator&.remove!
    Capybara.app_host = @previous_app_host
    WebAuthn.configuration.allowed_origins = @previous_origins if @previous_origins
  end

  test "registers a passkey and then signs in with it" do
    register_passkey

    assert_text_after_navigation I18n.t("flash.admin.passkeys.registered")
    assert_equal "Virtual key", users(:admin).passkeys.order(:id).last.name

    make_credential_discoverable
    Capybara.current_session.driver.browser.manage.delete_all_cookies
    visit new_admin_session_path
    click_button I18n.t("admin.sessions.new.sign_in_with_passkey")

    assert_current_path admin_root_path
  end

  test "refuses to register the same authenticator twice" do
    register_passkey
    assert_text_after_navigation I18n.t("flash.admin.passkeys.registered")

    register_passkey
    assert_text_after_navigation "This passkey is already registered."
    assert_equal 1, users(:admin).passkeys.where(name: "Virtual key").count
  end

  private

  # Chrome reports a node read mid-navigation as an "unknown error", which
  # Capybara doesn't retry the way it retries a stale element.
  def assert_text_after_navigation(text, attempts: 5)
    assert_text text
  rescue Selenium::WebDriver::Error::UnknownError => e
    raise unless e.message.include?("does not belong to the document") && (attempts -= 1).positive?

    retry
  end

  def register_passkey
    visit admin_passkeys_path
    fill_in "passkey_name", with: "Virtual key"
    click_button I18n.t("admin.passkeys.index.register_passkey")
  end

  # Platform passkeys are discoverable, which is what lets sign-in work without
  # naming a credential. The virtual authenticator only stores one that way when
  # registration asks for it, so re-add the registered key as discoverable.
  def make_credential_discoverable
    registered = @authenticator.credentials.sole
    @authenticator.remove_all_credentials
    @authenticator.add_credential(
      Selenium::WebDriver::Credential.resident(
        id: registered.id, rp_id: registered.rp_id, private_key: registered.private_key,
        user_handle: registered.user_handle, sign_count: registered.sign_count
      )
    )
  end
end
