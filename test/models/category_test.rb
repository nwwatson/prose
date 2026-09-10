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

  test "post_counts returns a hash of post counts keyed by category id" do
    counts = Category.post_counts
    assert_equal categories(:technology).posts.count, counts[categories(:technology).id]
    assert_equal categories(:design).posts.count, counts[categories(:design).id]
  end

  test "post_counts is zero for a category with no posts" do
    empty_category = Category.create!(name: "Empty", slug: "empty")
    counts = Category.post_counts
    assert_equal 0, counts.fetch(empty_category.id, 0)
  end
end
