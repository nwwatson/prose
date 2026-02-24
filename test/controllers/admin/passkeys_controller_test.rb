require "test_helper"

class Admin::PasskeysControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(:admin)
  end

  test "GET index requires authentication" do
    delete admin_session_path
    get admin_passkeys_path
    assert_redirected_to new_admin_session_path
  end

  test "GET index lists passkeys" do
    get admin_passkeys_path
    assert_response :success
    assert_select "td", text: "MacBook Touch ID"
  end

  test "POST registration_options returns JSON with challenge" do
    post registration_options_admin_passkeys_path, as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert json["challenge"].present?
    assert json["user"].present?
    assert_equal users(:admin).email, json["user"]["name"]
  end

  test "DELETE destroy removes passkey" do
    passkey = passkeys(:admin_passkey)

    assert_difference "Passkey.count", -1 do
      delete admin_passkey_path(passkey)
    end

    assert_redirected_to admin_passkeys_path
  end

  test "DELETE destroy is scoped to current user" do
    delete admin_session_path
    sign_in_as(:writer)

    passkey = passkeys(:admin_passkey)

    # Writer shouldn't be able to delete admin's passkey
    assert_no_difference "Passkey.count" do
      begin
        delete admin_passkey_path(passkey)
      rescue ActiveRecord::RecordNotFound
        # expected
      end
    end
  end
end
