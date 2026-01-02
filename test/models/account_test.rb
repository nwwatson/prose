# frozen_string_literal: true

require "test_helper"

class AccountTest < ActiveSupport::TestCase
  test "should require name" do
    account = Account.new
    assert_not account.valid?
    assert_includes account.errors[:name], "can't be blank"
  end

  test "should be valid with name" do
    account = Account.new(name: "Test Account")
    assert account.valid?
  end
end
