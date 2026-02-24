require "test_helper"

class AuthorsControllerTest < ActionDispatch::IntegrationTest
  test "GET index lists authors with handles" do
    get authors_path
    assert_response :success
    assert_select "h1", text: "Authors"
    assert_select "h2 a", text: identities(:admin_identity).name
    assert_select "h2 a", text: identities(:writer_identity).name
  end

  test "GET index does not list identities without users" do
    get authors_path
    assert_response :success
    assert_select "h2 a", text: identities(:subscriber_identity).name, count: 0
  end

  test "GET index includes meta tags" do
    get authors_path
    assert_response :success
    assert_select "meta[property='og:title']"
    assert_select "link[rel='canonical']"
  end

  test "GET show renders author profile" do
    identity = identities(:admin_identity)
    get author_path(identity, handle: identity.handle)
    assert_response :success
    assert_select "h1", text: identity.name
  end

  test "GET show displays author bio as markdown" do
    identity = identities(:admin_identity)
    get author_path(identity, handle: identity.handle)
    assert_response :success
    assert_select ".prose", text: /Site administrator/
  end

  test "GET show lists published posts by author" do
    identity = identities(:admin_identity)
    get author_path(identity, handle: identity.handle)
    assert_response :success
    assert_select "h3 a", text: posts(:published_post).title
  end

  test "GET show does not list draft posts" do
    identity = identities(:writer_identity)
    get author_path(identity, handle: identity.handle)
    assert_response :success
    assert_select "h3 a", text: posts(:draft_post).title, count: 0
  end

  test "GET show returns 404 for unknown handle" do
    get author_path(id: "nonexistent", handle: "nonexistent")
    assert_response :not_found
  end

  test "GET show includes JSON-LD Person schema" do
    identity = identities(:admin_identity)
    get author_path(identity, handle: identity.handle)
    assert_select "script[type='application/ld+json']"
  end

  test "GET show displays social links" do
    identity = identities(:admin_identity)
    get author_path(identity, handle: identity.handle)
    assert_response :success
    assert_select "a[href='https://example.com']"
    assert_select "a[href='https://x.com/adminuser']"
    assert_select "a[href='https://github.com/adminuser']"
  end

  test "GET show displays post count" do
    identity = identities(:admin_identity)
    get author_path(identity, handle: identity.handle)
    assert_response :success
    assert_match(/\d+ posts? published/, response.body)
  end
end
