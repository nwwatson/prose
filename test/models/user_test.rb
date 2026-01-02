# frozen_string_literal: true

require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    user = User.new(
      name: "Test User",
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    assert user.valid?
  end

  test "should require name" do
    user = users(:one)
    user.name = nil
    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
  end

  test "should require email" do
    user = users(:one)
    user.email = nil
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "should require unique email" do
    existing_user = users(:one)
    user = User.new(
      name: "Test User",
      email: existing_user.email,
      password: "password123"
    )
    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  test "should downcase email before saving" do
    user = User.new(
      name: "Test User",
      email: "TEST@EXAMPLE.COM",
      password: "password123"
    )
    user.save!
    assert_equal "test@example.com", user.email
  end

  test "should generate confirmation token before create" do
    user = User.new(
      name: "Test User",
      email: "test@example.com",
      password: "password123"
    )
    user.save!
    assert_not_nil user.confirmation_token
  end

  test "confirmed? should return true when confirmed_at is present" do
    user = users(:one)
    assert user.confirmed?
  end

  test "confirmed? should return false when confirmed_at is nil" do
    user = users(:two)
    assert_not user.confirmed?
  end

  test "confirm! should set confirmed_at and clear confirmation_token" do
    user = users(:two)
    assert_not user.confirmed?

    user.confirm!
    assert user.confirmed?
    assert_nil user.confirmation_token
  end

  test "should lock account after 5 failed attempts" do
    user = users(:one)

    5.times { user.increment_failed_attempts! }

    assert user.account_locked?
    assert_equal 5, user.failed_attempts
  end

  test "should reset failed attempts on successful sign in" do
    user = users(:one)
    user.update!(failed_attempts: 3)

    user.track_sign_in!(OpenStruct.new)

    assert_equal 0, user.failed_attempts
  end

  test "should track sign in statistics" do
    user = users(:one)
    original_count = user.sign_in_count

    user.track_sign_in!(OpenStruct.new)

    assert_equal original_count + 1, user.sign_in_count
    assert_not_nil user.current_sign_in_at
  end

  test "should associate with accounts" do
    user = users(:one)
    assert_respond_to user, :accounts
    assert user.accounts.any?
  end

  test "should associate with publications through accounts" do
    user = users(:one)
    assert_respond_to user, :publications
  end
end
