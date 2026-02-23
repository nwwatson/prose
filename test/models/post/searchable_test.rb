require "test_helper"

class Post::SearchableTest < ActiveSupport::TestCase
  test "search finds posts by title" do
    results = Post.search("Published")
    assert_includes results, posts(:published_post)
  end

  test "search finds posts by subtitle" do
    results = Post.search("published article")
    assert_includes results, posts(:published_post)
  end

  test "search finds posts by body content" do
    results = Post.search("quantum computing")
    assert_includes results, posts(:draft_post)
  end

  test "search returns empty for no match" do
    results = Post.search("xyznonexistent")
    assert_empty results
  end

  test "search returns none for blank query" do
    assert_empty Post.search("")
    assert_empty Post.search(nil)
  end

  test "search handles special characters safely" do
    results = Post.search('test "quotes" here')
    assert_kind_of ActiveRecord::Relation, results
  end

  test "search supports prefix matching on last token" do
    results = Post.search("innov")
    assert_includes results, posts(:published_post)
  end

  test "search chains with other scopes" do
    results = Post.published.search("Post")
    assert_includes results, posts(:published_post)
    refute_includes results, posts(:draft_post)
  end

  test "search_with_snippets returns hash with search results" do
    snippets = Post.search_with_snippets("quantum")
    assert snippets.key?(posts(:draft_post).id)

    result = snippets[posts(:draft_post).id]
    assert_kind_of Post::SearchResult, result
    assert_includes result.body_snippet, "<mark>"
  end

  test "search_with_snippets returns empty hash for blank query" do
    assert_equal({}, Post.search_with_snippets(""))
    assert_equal({}, Post.search_with_snippets(nil))
  end

  test "body_plain is updated on save" do
    post = posts(:published_post)
    post.update!(content: "<p>New body content here</p>")
    assert_equal "New body content here", post.reload.body_plain
  end
end
