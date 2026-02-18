require "test_helper"

class Post::SluggableTest < ActiveSupport::TestCase
  test "generates slug from title" do
    post = Post.new(title: "My Great Post", user: users(:admin))
    post.valid?
    assert_equal "my-great-post", post.slug
  end

  test "does not overwrite existing slug" do
    post = Post.new(title: "My Post", slug: "custom-slug", user: users(:admin))
    post.valid?
    assert_equal "custom-slug", post.slug
  end

  test "generates unique slug when duplicate exists" do
    Post.create!(title: "Duplicate Title", user: users(:admin))
    post = Post.new(title: "Duplicate Title", user: users(:admin))
    post.valid?
    assert_equal "duplicate-title-1", post.slug
  end

  test "validates slug format" do
    post = Post.new(title: "Test", slug: "Invalid Slug!", user: users(:admin))
    assert_not post.valid?
    assert post.errors[:slug].any?
  end
end
