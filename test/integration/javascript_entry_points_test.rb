require "test_helper"

# Public pages load the "application" entry point only; the admin, admin auth
# and editor layouts load "admin", which adds Lexxy and the admin controllers.
class JavascriptEntryPointsTest < ActionDispatch::IntegrationTest
  ADMIN_ONLY_PRELOAD = %r{/assets/(lexxy|activestorage|admin/)}

  test "a public post page preloads no admin modules" do
    get "/posts/#{posts(:published_post).slug}"
    assert_response :success

    preloads = modulepreload_hrefs
    assert preloads.any? { |href| href.include?("/controllers/bookmark_controller") }
    assert_empty preloads.grep(ADMIN_ONLY_PRELOAD)
    assert_empty preloads.grep(/actioncable/)
    assert_select "script[type=module]", text: /import "application"/
    assert_select "script[type=module]", text: /import "admin"/, count: 0
  end

  test "the admin sign-in page loads the admin entry point" do
    get new_admin_session_path
    assert_response :success

    assert_select "script[type=module]", text: /import "admin"/
    assert modulepreload_hrefs.any? { |href| href.include?("/admin/controllers/passkey_controller") }
  end

  test "the post editor loads the admin entry point with Lexxy" do
    sign_in_as(:admin)
    get edit_admin_post_path(posts(:draft_post))
    assert_response :success

    preloads = modulepreload_hrefs
    assert_select "script[type=module]", text: /import "admin"/
    assert preloads.any? { |href| href.include?("/lexxy") }
    assert preloads.any? { |href| href.include?("/admin/controllers/autosave_controller") }
    assert preloads.any? { |href| href.include?("/controllers/autogrow_controller") }
  end

  private
    def modulepreload_hrefs
      css_select("link[rel=modulepreload]").map { |link| link["href"] }
    end
end
