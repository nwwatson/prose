require "test_helper"

class Admin::ProfileControllerTest < ActionDispatch::IntegrationTest
  test "GET edit requires authentication" do
    get edit_admin_profile_path
    assert_redirected_to new_admin_session_path
  end

  test "GET edit renders for admin" do
    sign_in_as(:admin)
    get edit_admin_profile_path
    assert_response :success
    assert_select "h1", text: "Author Profile"
  end

  test "GET edit renders for writer" do
    sign_in_as(:writer)
    get edit_admin_profile_path
    assert_response :success
    assert_select "h1", text: "Author Profile"
  end

  test "PATCH update saves profile fields" do
    sign_in_as(:admin)
    patch admin_profile_path, params: {
      identity: {
        name: "New Name",
        handle: "new_handle",
        bio: "My **cool** bio",
        website_url: "https://example.org",
        twitter_handle: "newtwitter",
        github_handle: "newgithub"
      }
    }
    assert_redirected_to edit_admin_profile_path

    identity = identities(:admin_identity).reload
    assert_equal "New Name", identity.name
    assert_equal "new_handle", identity.handle
    assert_equal "My **cool** bio", identity.bio
    assert_equal "https://example.org", identity.website_url
    assert_equal "newtwitter", identity.twitter_handle
    assert_equal "newgithub", identity.github_handle
  end

  test "PATCH update strips @ from twitter handle" do
    sign_in_as(:admin)
    patch admin_profile_path, params: { identity: { twitter_handle: "@someone" } }
    assert_redirected_to edit_admin_profile_path
    assert_equal "someone", identities(:admin_identity).reload.twitter_handle
  end

  test "PATCH update rejects blank name" do
    sign_in_as(:admin)
    patch admin_profile_path, params: { identity: { name: "" } }
    assert_response :unprocessable_entity
  end

  test "PATCH update rejects invalid website URL" do
    sign_in_as(:admin)
    patch admin_profile_path, params: { identity: { website_url: "not-a-url" } }
    assert_response :unprocessable_entity
  end

  test "PATCH update rejects invalid twitter handle" do
    sign_in_as(:admin)
    patch admin_profile_path, params: { identity: { twitter_handle: "way too long handle name!!" } }
    assert_response :unprocessable_entity
  end

  test "GET edit shows link to public profile when handle present" do
    sign_in_as(:admin)
    get edit_admin_profile_path
    assert_select "a", text: "View public profile"
  end
end
