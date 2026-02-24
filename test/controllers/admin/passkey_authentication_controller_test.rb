require "test_helper"

class Admin::PasskeyAuthenticationControllerTest < ActionDispatch::IntegrationTest
  test "POST options returns JSON with challenge" do
    post admin_passkey_authentication_options_path
    assert_response :success

    json = JSON.parse(response.body)
    assert json["challenge"].present?
  end

  test "POST verify with invalid credential returns 422" do
    post admin_passkey_authentication_options_path
    assert_response :success

    post admin_passkey_authentication_verify_path, params: {
      credential: { id: "invalid", type: "public-key", response: {} }
    }, as: :json
    assert_response :unprocessable_entity
  end

  test "POST verify with valid credential creates session" do
    passkey = passkeys(:admin_passkey)

    post admin_passkey_authentication_options_path

    fake_credential = Object.new
    fake_credential.define_singleton_method(:id) { passkey.credential_id }
    fake_credential.define_singleton_method(:sign_count) { 6 }
    fake_credential.define_singleton_method(:verify) { |*_args, **_kwargs| true }

    original_from_get = WebAuthn::Credential.method(:from_get)
    WebAuthn::Credential.define_singleton_method(:from_get) { |*_args, **_kwargs| fake_credential }

    begin
      post admin_passkey_authentication_verify_path, params: {
        credential: {
          id: passkey.credential_id,
          rawId: passkey.credential_id,
          type: "public-key",
          response: {
            authenticatorData: "dGVzdA",
            clientDataJSON: "dGVzdA",
            signature: "dGVzdA"
          },
          clientExtensionResults: {}
        }
      }, as: :json

      assert_response :success
      json = JSON.parse(response.body)
      assert_equal admin_root_path, json["redirect_url"]
    ensure
      WebAuthn::Credential.define_singleton_method(:from_get, original_from_get)
    end
  end
end
