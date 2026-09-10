require "test_helper"

class SluggableTest < ActiveSupport::TestCase
  test "generates slug from source attribute" do
    post = Post.new(title: "My Great Post", user: users(:admin))
    post.valid?
    assert_equal "my-great-post", post.slug
  end

  test "does not overwrite existing slug" do
    post = Post.new(title: "My Post", slug: "custom-slug", user: users(:admin))
    post.valid?
    assert_equal "custom-slug", post.slug
  end

  test "uniquify appends a numeric suffix when the slug is taken" do
    Post.create!(title: "Duplicate Title", user: users(:admin))
    post = Post.new(title: "Duplicate Title", user: users(:admin))
    post.valid?
    assert_equal "duplicate-title-1", post.slug
  end

  test "uniquify: false does not disambiguate duplicate slugs" do
    Category.create!(name: "Existing Category", slug: "shared-slug")
    category = Category.new(name: "Shared Slug")
    category.valid?
    assert_equal "shared-slug", category.slug
    assert_not category.valid?
    assert_includes category.errors[:slug], "has already been taken"
  end

  test "validates slug format" do
    post = Post.new(title: "Test", slug: "Invalid Slug!", user: users(:admin))
    assert_not post.valid?
    assert post.errors[:slug].any?
  end
end
