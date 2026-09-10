require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  test "GET index renders home page" do
    get root_path
    assert_response :success
    assert_select "h2", text: posts(:featured_post).title
  end

  test "GET index performs at most one site_settings query" do
    query_count = 0
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |_name, _start, _finish, _id, payload|
      query_count += 1 if payload[:name] == "SiteSetting Load"
    end

    get root_path

    assert_equal 1, query_count
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end

  test "GET index shows non-featured posts" do
    get root_path
    assert_response :success
    assert_select "h3", text: posts(:published_post).title
  end

  test "GET index does not show draft posts" do
    get root_path
    assert_response :success
    assert_select "h3", text: posts(:draft_post).title, count: 0
  end

  test "GET show renders published post" do
    get post_path(posts(:published_post), slug: posts(:published_post).slug)
    assert_response :success
    assert_select "h1", text: posts(:published_post).title
  end

  test "GET show returns 404 for draft post" do
    get post_path(posts(:draft_post), slug: posts(:draft_post).slug)
    assert_response :not_found
  end

  test "GET show renders the published date in Spanish when site locale is es" do
    SiteSetting.current.update!(locale: "es")
    post = posts(:published_post)

    get post_path(post, slug: post.slug)

    assert_response :success
    assert_select "time", text: I18n.l(post.published_at.to_date, format: :long, locale: :es)
  ensure
    SiteSetting.current.update!(locale: "en")
  end

  test "GET show includes meta tags" do
    get post_path(posts(:published_post), slug: posts(:published_post).slug)
    assert_response :success
    assert_select "meta[property='og:title']" do |elements|
      assert_equal posts(:published_post).title, elements.first["content"]
    end
  end

  test "GET show includes JSON-LD" do
    get post_path(posts(:published_post), slug: posts(:published_post).slug)
    assert_select "script[type='application/ld+json']"
  end

  test "GET index with search query filters results" do
    get root_path(q: "Published")
    assert_response :success
    assert_select "h3", text: posts(:published_post).title
  end

  test "GET index with search shows body snippet" do
    get root_path(q: "innovation")
    assert_response :success
    assert_select "mark"
  end

  test "GET index with non-matching search shows no posts" do
    get root_path(q: "xyznonexistent")
    assert_response :success
  end

  test "GET index shows search snippet even when the plain listing was cached first" do
    with_fragment_caching do
      get root_path
      assert_response :success
      assert_select "mark", count: 0

      get root_path(q: "innovation")
      assert_response :success
      assert_select "mark"
    end
  end

  test "GET index includes dark theme style tag" do
    get root_path
    assert_response :success
    assert_select "style", /root\.dark/
  end

  test "GET index preloads author identities without an N+1 query" do
    # One preload query for the featured post collection, one for the rest of the
    # listing — constant regardless of how many posts or distinct authors are shown.
    assert_query_count(2, table: "identities") { get root_path }
  end

  test "GET show comment query count does not grow with comment or reply count" do
    post = posts(:published_post)
    identity = identities(:subscriber_identity)
    replier = identities(:from_published_post_identity)

    3.times do |i|
      top_level = Comment.create!(post: post, identity: identity, body: "Top level #{i}", approved: true)
      2.times do |j|
        Comment.create!(post: post, identity: replier, parent_comment_id: top_level.id, body: "Reply #{j}", approved: true)
      end
      Comment.create!(post: post, identity: replier, parent_comment_id: top_level.id, body: "Unapproved reply", approved: false)
    end

    comment_queries = 0
    callback = lambda do |*, payload|
      comment_queries += 1 if payload[:sql].match?(/FROM "comments"/)
    end

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      get post_path(post, slug: post.slug)
    end

    assert_response :success
    assert_equal 2, comment_queries
    assert_select ".comment__body", text: /Unapproved reply/, count: 0
  end
end
