require "test_helper"

# Authors are routed with `param: :handle`, so their URLs must be built with
# `handle:` alone. Passing the identity positionally as well pushes it into the
# optional :format segment and yields "/authors/<handle>.<id>".
class AuthorLinksTest < ActionView::TestCase
  include ApplicationHelper
  include MetaTagsHelper
  include StructuredDataHelper

  setup do
    @identity = identities(:admin_identity)
    @handle = @identity.handle
    @user = users(:admin)
  end

  test "author_link points at the literal author path" do
    html = author_link(@user)

    assert_includes html, %(href="/authors/#{@handle}")
    refute_includes html, "#{@handle}.#{@identity.id}"
  end

  test "json_ld_for_author url is the literal author path" do
    data = JSON.parse(Nokogiri::HTML5.fragment(json_ld_for_author(@identity)).text)

    assert_equal "/authors/#{@handle}", URI(data["url"]).path
  end
end
