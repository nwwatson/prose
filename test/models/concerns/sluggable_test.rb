# frozen_string_literal: true

require "test_helper"

class SluggableTest < ActiveSupport::TestCase
  # Create a test model that includes Sluggable for testing
  def setup
    @test_class = Class.new(ApplicationRecord) do
      include Sluggable

      self.table_name = "publications" # Use existing table for testing

      def title
        name # Use name as title for slug generation
      end
    end

    @account = Account.create!(name: "Test Account")
  end

  test "should generate slug from title on creation" do
    record = @test_class.new(name: "Test Title", account_id: @account.id)
    record.save!

    assert_equal "test-title", record.slug
  end

  test "should not regenerate slug if already present" do
    record = @test_class.new(name: "Test Title", slug: "custom-slug", account_id: @account.id)
    record.save!

    assert_equal "custom-slug", record.slug
  end

  test "should generate unique slug when conflict exists" do
    # Create first record
    first = @test_class.create!(name: "Test Title", account_id: @account.id)
    assert_equal "test-title", first.slug

    # Create second record with same title
    second = @test_class.new(name: "Test Title", account_id: @account.id)
    second.save!

    assert_equal "test-title-1", second.slug
  end

  test "should increment counter for multiple conflicts" do
    # Create first record
    @test_class.create!(name: "Test Title", account_id: @account.id)

    # Create second record
    @test_class.create!(name: "Test Title", account_id: @account.id)

    # Create third record
    third = @test_class.new(name: "Test Title", account_id: @account.id)
    third.save!

    assert_equal "test-title-2", third.slug
  end

  test "should use slug for to_param" do
    record = @test_class.create!(name: "Test Title", account_id: @account.id)
    assert_equal "test-title", record.to_param
  end

  test "should require slug presence" do
    record = @test_class.new(name: "", account_id: @account.id)
    assert_not record.valid?
    assert_includes record.errors[:slug], "can't be blank"
  end

  test "should validate slug uniqueness within scope" do
    @test_class.create!(name: "Test Title", account_id: @account.id)

    duplicate = @test_class.new(name: "Different Title", slug: "test-title", account_id: @account.id)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:slug], "has already been taken"
  end

  test "should handle special characters in title" do
    record = @test_class.new(name: "Test & Title with Spëcial Chars!", account_id: @account.id)
    record.save!

    assert_equal "test-title-with-special-chars", record.slug
  end

  test "should handle empty title gracefully" do
    record = @test_class.new(name: "", account_id: @account.id)
    # This should be invalid due to slug presence validation
    assert_not record.valid?
  end
end
