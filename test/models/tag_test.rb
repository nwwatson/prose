require "test_helper"

class TagTest < ActiveSupport::TestCase
  test "valid tag" do
    tag = Tag.new(name: "JavaScript")
    assert tag.valid?
  end

  test "requires name" do
    tag = Tag.new
    assert_not tag.valid?
  end

  test "generates slug from name" do
    tag = Tag.new(name: "JavaScript")
    tag.valid?
    assert_equal "javascript", tag.slug
  end

  test "requires unique name" do
    tag = Tag.new(name: "Ruby")
    assert_not tag.valid?
  end

  test "post_counts returns a hash of post counts keyed by tag id" do
    counts = Tag.post_counts
    assert_equal tags(:ruby).posts.count, counts[tags(:ruby).id]
    assert_equal tags(:css).posts.count, counts[tags(:css).id]
  end

  test "post_counts is zero for a tag with no posts" do
    empty_tag = Tag.create!(name: "Empty")
    counts = Tag.post_counts
    assert_equal 0, counts.fetch(empty_tag.id, 0)
  end
end
