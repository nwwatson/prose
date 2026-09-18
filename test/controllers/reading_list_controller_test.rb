require "test_helper"

class ReadingListControllerTest < ActionDispatch::IntegrationTest
  test "anonymous readers get the localStorage-backed shell and a sync prompt" do
    get reading_list_path

    assert_response :success
    assert_select "meta[name='reading-list'][content='local']"
    assert_select "meta[name='robots'][content='noindex']"
    assert_select "[data-controller='reading-list'][data-reading-list-url-value=?]", reading_list_posts_path
    assert_select "turbo-frame#reading_list_posts"
    assert_select ".subscribe-cta form[action=?]", subscriptions_path
  end

  test "signed-in subscribers see their saved live posts server-rendered" do
    sign_in_subscriber(subscribers(:confirmed))

    get reading_list_path

    assert_response :success
    assert_select "meta[name='reading-list'][content='account']"
    assert_select "[data-controller='reading-list']", count: 0
    assert_select ".post-card__title", text: posts(:featured_post).title
    assert_select ".post-card__title", text: posts(:published_post).title
    assert_select ".post-card__title", text: posts(:draft_post).title, count: 0
    assert_select ".subscribe-cta", count: 0
  end

  test "signed-in readers with nothing saved see the empty state" do
    sign_in_subscriber(subscribers(:with_token))

    get reading_list_path

    assert_select ".empty-state__text", text: I18n.t("reading_list.show.empty")
  end

  test "staff users signed into the public site get an account-backed list" do
    sign_in_as(:admin)

    get reading_list_path

    assert_select "meta[name='reading-list'][content='account'][data-key=?]", "identity-#{users(:admin).identity_id}"
  end
end
