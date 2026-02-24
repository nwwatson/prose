require "test_helper"

class Identity::ProfileableTest < ActiveSupport::TestCase
  test "bio_html renders markdown" do
    identity = identities(:admin_identity)
    identity.bio = "Hello **world**"
    assert_match "<strong>world</strong>", identity.bio_html
  end

  test "bio_html returns empty string for blank bio" do
    identity = identities(:writer_identity)
    identity.bio = nil
    assert_equal "", identity.bio_html
  end

  test "twitter_url returns url when handle present" do
    identity = identities(:admin_identity)
    assert_equal "https://x.com/adminuser", identity.twitter_url
  end

  test "twitter_url returns nil when handle blank" do
    identity = identities(:writer_identity)
    assert_nil identity.twitter_url
  end

  test "github_url returns url when handle present" do
    identity = identities(:admin_identity)
    assert_equal "https://github.com/adminuser", identity.github_url
  end

  test "github_url returns nil when handle blank" do
    identity = identities(:writer_identity)
    assert_nil identity.github_url
  end

  test "has_social_links? returns true when any link present" do
    identity = identities(:admin_identity)
    assert identity.has_social_links?
  end

  test "has_social_links? returns false when no links" do
    identity = identities(:writer_identity)
    refute identity.has_social_links?
  end

  test "has_profile? returns true with bio" do
    identity = identities(:admin_identity)
    assert identity.has_profile?
  end

  test "has_profile? returns false with no profile data" do
    identity = identities(:writer_identity)
    refute identity.has_profile?
  end

  test "twitter_handle normalizes by stripping @" do
    identity = identities(:admin_identity)
    identity.twitter_handle = "@someone"
    assert_equal "someone", identity.twitter_handle
  end

  test "validates twitter handle format" do
    identity = identities(:admin_identity)
    identity.twitter_handle = "invalid handle!"
    refute identity.valid?
    assert identity.errors[:twitter_handle].any?
  end

  test "validates github handle format" do
    identity = identities(:admin_identity)
    identity.github_handle = "invalid handle!"
    refute identity.valid?
    assert identity.errors[:github_handle].any?
  end

  test "validates website_url format" do
    identity = identities(:admin_identity)
    identity.website_url = "not-a-url"
    refute identity.valid?
    assert identity.errors[:website_url].any?
  end

  test "allows blank social fields" do
    identity = identities(:admin_identity)
    identity.website_url = ""
    identity.twitter_handle = ""
    identity.github_handle = ""
    assert identity.valid?
  end

  test "authors scope returns identities with users" do
    authors = Identity.authors
    assert_includes authors, identities(:admin_identity)
    assert_includes authors, identities(:writer_identity)
    refute_includes authors, identities(:subscriber_identity)
  end

  test "with_handle scope returns identities with handles" do
    identities_with_handles = Identity.with_handle
    assert_includes identities_with_handles, identities(:admin_identity)
    assert_includes identities_with_handles, identities(:writer_identity)
  end
end
