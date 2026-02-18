require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid user" do
    user = User.new(email: "new@example.com", display_name: "New User", password: "P@ssw0rd!Strong1", password_confirmation: "P@ssw0rd!Strong1")
    assert user.valid?
  end

  test "auto-builds identity on create" do
    user = User.new(email: "new@example.com", display_name: "New User", password: "P@ssw0rd!Strong1", password_confirmation: "P@ssw0rd!Strong1")
    assert user.valid?
    assert_not_nil user.identity
    assert_equal "New User", user.identity.name
  end

  test "display_name delegates to identity" do
    user = users(:admin)
    assert_equal "Admin User", user.display_name
  end

  test "requires email" do
    user = User.new(display_name: "Test", password: "P@ssw0rd!Strong1", password_confirmation: "P@ssw0rd!Strong1")
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "requires unique email" do
    user = User.new(email: users(:admin).email, display_name: "Test", password: "P@ssw0rd!Strong1", password_confirmation: "P@ssw0rd!Strong1")
    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  test "normalizes email to lowercase" do
    user = User.new(email: "  Admin@Example.COM  ", display_name: "Test", password: "P@ssw0rd!Strong1", password_confirmation: "P@ssw0rd!Strong1")
    assert_equal "admin@example.com", user.email
  end

  test "requires valid email format" do
    user = User.new(email: "notanemail", display_name: "Test", password: "P@ssw0rd!Strong1", password_confirmation: "P@ssw0rd!Strong1")
    assert_not user.valid?
    assert_includes user.errors[:email], "is invalid"
  end

  test "role defaults to writer" do
    user = User.new
    assert user.writer?
  end

  test "admin role" do
    assert users(:admin).admin?
  end

  test "writer role" do
    assert users(:writer).writer?
  end
end
