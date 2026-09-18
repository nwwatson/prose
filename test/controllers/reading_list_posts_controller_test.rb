require "test_helper"

class ReadingListPostsControllerTest < ActionDispatch::IntegrationTest
  test "renders live posts for the given ids in the order given" do
    ids = [ posts(:design_post), posts(:published_post) ].map(&:id)

    get reading_list_posts_path(ids: ids.join(","))

    assert_response :success
    assert_select "turbo-frame#reading_list_posts"
    titles = css_select(".post-card__title").map { |node| node.text.strip }
    assert_equal [ posts(:design_post).title, posts(:published_post).title ], titles
  end

  test "drops drafts, unknown ids, and junk" do
    get reading_list_posts_path(ids: "#{posts(:draft_post).id},999999,abc,-1,#{posts(:published_post).id}")

    assert_select ".post-card__title", count: 1
    assert_select ".post-card__title", text: posts(:published_post).title
  end

  test "renders the empty state with no ids" do
    get reading_list_posts_path

    assert_response :success
    assert_select ".empty-state__text", text: I18n.t("reading_list.show.empty")
  end

  test "does not use the layout" do
    get reading_list_posts_path(ids: posts(:published_post).id)

    assert_select "header.masthead", count: 0
  end
end
