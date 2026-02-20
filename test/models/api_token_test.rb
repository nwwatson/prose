require "test_helper"

class ApiTokenTest < ActiveSupport::TestCase
  test "generate_for creates a token with prose_ prefix" do
    user = users(:admin)
    record, raw_token = ApiToken.generate_for(user, name: "Test Token")

    assert record.persisted?
    assert raw_token.start_with?("prose_")
    assert_equal "Test Token", record.name
    assert_equal raw_token.first(12), record.token_prefix
    assert_equal Digest::SHA256.hexdigest(raw_token), record.token_digest
  end

  test "find_by_raw_token returns active token" do
    raw_token = "prose_admin_test_token_1234567890abcdef"
    token = ApiToken.find_by_raw_token(raw_token)

    assert_not_nil token
    assert_equal api_tokens(:admin_token), token
  end

  test "find_by_raw_token returns nil for revoked token" do
    raw_token = "prose_revoked_test_token_1234567890abcdef"
    token = ApiToken.find_by_raw_token(raw_token)

    assert_nil token
  end

  test "find_by_raw_token returns nil for invalid token" do
    token = ApiToken.find_by_raw_token("prose_nonexistent_token")

    assert_nil token
  end

  test "find_by_raw_token returns nil for blank token" do
    assert_nil ApiToken.find_by_raw_token(nil)
    assert_nil ApiToken.find_by_raw_token("")
  end

  test "revoke! sets revoked_at" do
    token = api_tokens(:admin_token)
    assert_not token.revoked?

    token.revoke!

    assert token.revoked?
    assert_not_nil token.revoked_at
  end

  test "touch_usage! updates last_used_at and last_used_ip" do
    token = api_tokens(:admin_token)
    assert_nil token.last_used_at

    token.touch_usage!(ip_address: "192.168.1.1")

    assert_not_nil token.last_used_at
    assert_equal "192.168.1.1", token.last_used_ip
  end

  test "active scope excludes revoked tokens" do
    active = ApiToken.active
    assert_includes active, api_tokens(:admin_token)
    assert_includes active, api_tokens(:writer_token)
    assert_not_includes active, api_tokens(:revoked_token)
  end

  test "token_digest must be unique" do
    user = users(:admin)
    existing = api_tokens(:admin_token)

    duplicate = ApiToken.new(
      user: user,
      name: "Duplicate",
      token_digest: existing.token_digest,
      token_prefix: "prose_dupl"
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:token_digest], "has already been taken"
  end

  test "user can generate token via concern" do
    user = users(:admin)
    record, raw_token = user.generate_api_token!(name: "Via Concern")

    assert record.persisted?
    assert raw_token.start_with?("prose_")
    assert_equal user, record.user
  end
end
