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

  test "post_counts returns counts keyed by tag id" do
    counts = Tag.post_counts
    assert_equal 3, counts[tags(:ruby).id]
    assert_equal 3, counts[tags(:rails).id]
    assert_equal 1, counts[tags(:css).id]
  end

  test "post_counts defaults to zero for a tag id with no posts" do
    tag = Tag.create!(name: "Unused")
    counts = Tag.post_counts
    assert_equal 0, counts.fetch(tag.id, 0)
  end
end
