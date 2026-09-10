require "test_helper"

class Api::V1::SiteControllerTest < ActionDispatch::IntegrationTest
  def auth_header
    { "Authorization" => "Bearer prose_admin_test_token_1234567890abcdef" }
  end

  test "returns site info" do
    get "/api/v1/site", headers: auth_header
    assert_response :success

    body = JSON.parse(response.body)
    assert body.key?("site_name")
    assert body.key?("categories")
    assert body.key?("tags")
    assert body["post_counts"].key?("total")
  end
end
