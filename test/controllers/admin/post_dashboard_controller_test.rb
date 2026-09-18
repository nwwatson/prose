require "test_helper"

class Admin::PostDashboardControllerTest < ActionDispatch::IntegrationTest
  include ActivityPubTestHelper

  setup { sign_in_as(:admin) }

  test "shows fediverse likes once federation is enabled" do
    enable_federation!
    post = posts(:published_post)
    post.fediverse_likes.create!(fediverse_actor: remote_actor)

    get admin_post_dashboard_path(post)

    assert_response :success
    assert_match I18n.t("admin.post_dashboard.show.fediverse_likes"), response.body
  end

  test "hides fediverse likes when federation has never been used" do
    get admin_post_dashboard_path(posts(:published_post))

    assert_response :success
    assert_no_match I18n.t("admin.post_dashboard.show.fediverse_likes"), response.body
  end
end
