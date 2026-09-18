require "test_helper"

class BookmarkButtonsTest < ActionDispatch::IntegrationTest
  test "post cards render a hidden, reader-agnostic bookmark button" do
    get root_path

    post = posts(:published_post)
    assert_select "button.bookmark-btn[hidden][aria-pressed='false'][data-bookmark-post-id-value='#{post.id}']"
  end

  test "the post page renders a bookmark button for the post" do
    post = posts(:published_post)

    get post_path(slug: post.slug)

    assert_select ".post-detail__meta button.bookmark-btn[data-controller='bookmark'][data-bookmark-post-id-value='#{post.id}']"
  end

  test "cached post cards never carry one reader's saved state to another" do
    with_fragment_caching do
      sign_in_subscriber(subscribers(:confirmed))
      get root_path
      signed_in_cards = css_select("button.bookmark-btn").map(&:to_html)

      delete subscriber_session_path
      get root_path

      assert_equal signed_in_cards, css_select("button.bookmark-btn").map(&:to_html)
      assert_select "button.bookmark-btn[aria-pressed='true']", count: 0
    end
  end

  test "the layout carries the signed-in reader's saved ids for the bookmark JS" do
    sign_in_subscriber(subscribers(:confirmed))

    get root_path

    meta = css_select("meta[name='reading-list']").first
    assert_equal "account", meta["content"]
    assert_equal [ posts(:featured_post).id, posts(:published_post).id ], JSON.parse(meta["data-post-ids"])
    assert_equal reading_list_items_path, meta["data-items-url"]
    assert_equal reading_list_import_path, meta["data-import-url"]
  end

  test "the masthead links to the reading list" do
    get root_path

    assert_select ".masthead__actions a[href=?]", reading_list_path
  end
end
