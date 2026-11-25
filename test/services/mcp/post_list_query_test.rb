require "test_helper"

class Mcp::PostListQueryTest < ActiveSupport::TestCase
  test "filters by category name or slug" do
    result = Mcp::PostListQuery.call(category: "design")

    assert result.posts.any?
    assert result.posts.all? { |post| post.category == categories(:design) }
  end

  test "an unknown category matches no posts" do
    result = Mcp::PostListQuery.call(category: "no-such-category")

    assert_empty result.posts
    assert_equal 0, result.total
  end

  test "filters by tag without duplicating posts" do
    result = Mcp::PostListQuery.call(tag: "ruby")

    assert result.posts.any?
    assert result.posts.all? { |post| post.tags.include?(tags(:ruby)) }
    assert_equal result.posts.map(&:id).uniq, result.posts.map(&:id)
  end

  test "an unknown tag matches no posts" do
    result = Mcp::PostListQuery.call(tag: "no-such-tag")

    assert_empty result.posts
    assert_equal 0, result.total
  end

  test "a page below 1 is treated as the first page" do
    first = Mcp::PostListQuery.call(page: 1, per_page: 2)

    [ 0, -3 ].each do |page|
      result = Mcp::PostListQuery.call(page: page, per_page: 2)
      assert_equal 1, result.page
      assert_equal first.posts, result.posts
    end
  end

  test "per_page defaults to 20, falls back when below 1 and is capped at 50" do
    assert_equal 20, Mcp::PostListQuery.call.per_page
    assert_equal 20, Mcp::PostListQuery.call(per_page: 0).per_page
    assert_equal 50, Mcp::PostListQuery.call(per_page: 500).per_page
  end

  test "accepts string params as sent by the REST API" do
    result = Mcp::PostListQuery.call("page" => "2", "per_page" => "1")

    assert_equal 2, result.page
    assert_equal 1, result.per_page
    assert_equal Post.count, result.total
  end
end
