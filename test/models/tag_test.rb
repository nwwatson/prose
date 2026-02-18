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
end
