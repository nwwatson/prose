require "test_helper"

class IdentityBackedTest < ActiveSupport::TestCase
  test "requires email" do
    subscriber = Subscriber.new
    assert_not subscriber.valid?
    assert_includes subscriber.errors[:email], "can't be blank"
  end

  test "validates email format" do
    subscriber = Subscriber.new(email: "not-an-email")
    assert_not subscriber.valid?
    assert_includes subscriber.errors[:email], "is invalid"
  end

  test "normalizes email" do
    subscriber = Subscriber.new(email: "  Test@Example.COM  ")
    assert_equal "test@example.com", subscriber.email
  end

  test "builds identity on create using default_identity_name" do
    subscriber = Subscriber.new(email: "new@example.com")
    subscriber.valid?
    assert_not_nil subscriber.identity
    assert_equal "new", subscriber.identity.name
  end

  test "does not overwrite an already-assigned identity" do
    identity = identities(:unconfirmed_identity)
    subscriber = Subscriber.new(email: "new@example.com", identity: identity)
    subscriber.valid?
    assert_equal identity, subscriber.identity
  end

  test "including model can override default_identity_name" do
    user = User.new(email: "new@example.com", display_name: "Custom Name", password: "P@ssw0rd!Strong1", password_confirmation: "P@ssw0rd!Strong1")
    user.valid?
    assert_equal "Custom Name", user.identity.name
  end
end
