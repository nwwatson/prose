require "test_helper"

class PasskeyTest < ActiveSupport::TestCase
  test "valid passkey" do
    passkey = Passkey.new(
      user: users(:admin),
      credential_id: "new-credential-id",
      public_key: "new-public-key",
      name: "Test Passkey"
    )
    assert passkey.valid?
  end

  test "requires credential_id" do
    passkey = Passkey.new(user: users(:admin), public_key: "key", name: "Test")
    assert_not passkey.valid?
    assert_includes passkey.errors[:credential_id], "can't be blank"
  end

  test "requires public_key" do
    passkey = Passkey.new(user: users(:admin), credential_id: "cred", name: "Test")
    assert_not passkey.valid?
    assert_includes passkey.errors[:public_key], "can't be blank"
  end

  test "requires name" do
    passkey = Passkey.new(user: users(:admin), credential_id: "cred", public_key: "key")
    assert_not passkey.valid?
    assert_includes passkey.errors[:name], "can't be blank"
  end

  test "credential_id must be unique" do
    existing = passkeys(:admin_passkey)
    duplicate = Passkey.new(
      user: users(:admin),
      credential_id: existing.credential_id,
      public_key: "different-key",
      name: "Duplicate"
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:credential_id], "has already been taken"
  end

  test "touch_usage! updates last_used_at" do
    passkey = passkeys(:admin_passkey)
    original_time = passkey.last_used_at

    travel 1.hour do
      passkey.touch_usage!
      assert_not_equal original_time, passkey.reload.last_used_at
    end
  end

  test "belongs to user" do
    passkey = passkeys(:admin_passkey)
    assert_equal users(:admin), passkey.user
  end

  test "sign_count defaults to 0" do
    passkey = Passkey.new
    assert_equal 0, passkey.sign_count
  end

  test "user passkey_registered? returns true when passkeys exist" do
    user = users(:admin)
    assert user.passkey_registered?
  end

  test "user passkey_registered? returns false when no passkeys" do
    user = users(:writer)
    assert_not user.passkey_registered?
  end
end
