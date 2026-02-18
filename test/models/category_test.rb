require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  test "valid category" do
    category = Category.new(name: "New Category")
    assert category.valid?
  end

  test "requires name" do
    category = Category.new
    assert_not category.valid?
    assert_includes category.errors[:name], "can't be blank"
  end

  test "generates slug from name" do
    category = Category.new(name: "New Category")
    category.valid?
    assert_equal "new-category", category.slug
  end

  test "requires unique name" do
    category = Category.new(name: "Technology")
    assert_not category.valid?
  end

  test "ordered scope sorts by position" do
    categories = Category.ordered
    assert_equal categories(:technology), categories.first
  end
end
