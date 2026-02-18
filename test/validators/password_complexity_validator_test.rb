require "test_helper"

class PasswordComplexityValidatorTest < ActiveSupport::TestCase
  def build_user(password)
    User.new(email: "test-#{SecureRandom.hex(4)}@example.com", display_name: "Test User", password: password, password_confirmation: password)
  end

  test "accepts a strong password" do
    user = build_user("P@ssw0rd!Strong1")
    assert user.valid?
  end

  test "rejects password shorter than 12 characters" do
    user = build_user("P@ssw0rd!1")
    assert_not user.valid?
    assert user.errors[:password].any? { |e| e.include?("short") }
  end

  test "rejects password without uppercase" do
    user = build_user("p@ssw0rd!strong1")
    assert_not user.valid?
    assert user.errors[:password].any? { |e| e.include?("uppercase") }
  end

  test "rejects password without lowercase" do
    user = build_user("P@SSW0RD!STRONG1")
    assert_not user.valid?
    assert user.errors[:password].any? { |e| e.include?("lowercase") }
  end

  test "rejects password without number" do
    user = build_user("P@ssword!Strong")
    assert_not user.valid?
    assert user.errors[:password].any? { |e| e.include?("number") }
  end

  test "rejects password without symbol" do
    user = build_user("Passw0rdStrong1")
    assert_not user.valid?
    assert user.errors[:password].any? { |e| e.include?("symbol") }
  end

  test "skips validation when password is blank" do
    user = users(:admin)
    user.display_name = "Updated Name"
    assert user.valid?
  end
end
