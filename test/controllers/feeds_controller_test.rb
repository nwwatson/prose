require "test_helper"

class FeedsControllerTest < ActionDispatch::IntegrationTest
  test "GET index renders RSS feed" do
    get feed_path(format: :xml)
    assert_response :success
    assert_equal "application/xml; charset=utf-8", response.content_type
    assert_includes response.body, posts(:published_post).title
  end

  test "RSS feed does not include draft posts" do
    get feed_path(format: :xml)
    assert_not_includes response.body, posts(:draft_post).title
  end

  test "GET index preloads author identities in a single query" do
    assert_query_count(1, table: "identities") { get feed_path(format: :xml) }
  end

  test "RSS item link and guid use the plain post URL" do
    get feed_path(format: :xml)
    slug = posts(:published_post).slug
    assert_match %r{<link>http://[^<]+/posts/#{slug}</link>}, response.body
    assert_match %r{<guid>http://[^<]+/posts/#{slug}</guid>}, response.body
    assert_no_match(/#{slug}\.#{slug}/, response.body)
  end
end
