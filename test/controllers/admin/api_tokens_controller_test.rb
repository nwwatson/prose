require "test_helper"

class Admin::ApiTokensControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    get "/admin/api_tokens"
    assert_redirected_to "/admin/session/new"
  end

  test "admin index lists every user's tokens" do
    sign_in_as(:admin)
    get "/admin/api_tokens"

    assert_response :success
    assert_includes response.body, api_tokens(:admin_token).name
    assert_includes response.body, api_tokens(:writer_token).name
    assert_includes response.body, api_tokens(:revoked_token).name
  end

  test "writer index lists only the writer's own tokens" do
    sign_in_as(:writer)
    get "/admin/api_tokens"

    assert_response :success
    assert_includes response.body, api_tokens(:writer_token).name
    assert_not_includes response.body, api_tokens(:admin_token).name
    assert_not_includes response.body, api_tokens(:revoked_token).name
  end

  test "index never renders token digests" do
    sign_in_as(:admin)
    get "/admin/api_tokens"

    ApiToken.find_each { |token| assert_not_includes response.body, token.token_digest }
  end

  test "create generates a token for the current user and shows the raw token once" do
    sign_in_as(:writer)

    assert_difference -> { users(:writer).api_tokens.count }, 1 do
      post "/admin/api_tokens", params: { name: "CI bot" }
    end

    assert_redirected_to "/admin/api_tokens"
    raw_token = flash[:raw_token]
    assert raw_token.start_with?(ApiToken::TOKEN_PREFIX)

    token = users(:writer).api_tokens.order(:created_at).last
    assert_equal "CI bot", token.name
    assert_equal Digest::SHA256.hexdigest(raw_token), token.token_digest
    assert_equal raw_token.first(12), token.token_prefix

    follow_redirect!
    assert_includes response.body, raw_token

    get "/admin/api_tokens"
    assert_not_includes response.body, raw_token
  end

  test "create with a blank name re-renders the list with an error" do
    sign_in_as(:writer)

    assert_no_difference "ApiToken.count" do
      post "/admin/api_tokens", params: { name: "" }
    end

    assert_response :unprocessable_entity
    assert_includes CGI.unescapeHTML(response.body), "Name can't be blank"
    assert_includes response.body, api_tokens(:writer_token).name
    assert_not_includes response.body, api_tokens(:admin_token).name
    assert_nil flash[:raw_token]
  end

  test "admin can revoke another user's token" do
    sign_in_as(:admin)
    token = api_tokens(:writer_token)

    delete "/admin/api_tokens/#{token.id}"

    assert_redirected_to "/admin/api_tokens"
    assert token.reload.revoked?
  end

  test "writer can revoke their own token" do
    sign_in_as(:writer)
    token = api_tokens(:writer_token)

    delete "/admin/api_tokens/#{token.id}"

    assert_redirected_to "/admin/api_tokens"
    assert token.reload.revoked?
  end

  test "writer cannot revoke another user's token" do
    sign_in_as(:writer)
    token = api_tokens(:admin_token)

    delete "/admin/api_tokens/#{token.id}"

    assert_response :not_found
    assert_not token.reload.revoked?
  end
end
