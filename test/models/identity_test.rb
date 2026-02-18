require "test_helper"

class IdentityTest < ActiveSupport::TestCase
  test "valid identity" do
    identity = Identity.new(name: "Test User")
    assert identity.valid?
  end

  test "requires name" do
    identity = Identity.new
    assert_not identity.valid?
    assert_includes identity.errors[:name], "can't be blank"
  end

  test "handle uniqueness" do
    identity = Identity.new(name: "Test", handle: "subscriber1")
    assert_not identity.valid?
    assert identity.errors[:handle].any?
  end

  test "handle format validation" do
    identity = Identity.new(name: "Test", handle: "bad handle!")
    assert_not identity.valid?
    assert identity.errors[:handle].any?
  end

  test "handle length validation" do
    identity = Identity.new(name: "Test", handle: "ab")
    assert_not identity.valid?
    assert identity.errors[:handle].any?
  end

  test "handle normalization" do
    identity = Identity.new(name: "Test", handle: "  MyHandle  ")
    assert_equal "myhandle", identity.handle
  end

  test "handle allows nil" do
    identity = Identity.new(name: "Test", handle: nil)
    assert identity.valid?
  end
end
