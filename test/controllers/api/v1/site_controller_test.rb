require "test_helper"

class Api::V1::SiteControllerTest < ActionDispatch::IntegrationTest
  test "returns site info" do
    get "/api/v1/site", headers: api_auth_header
    assert_response :success

    body = JSON.parse(response.body)
    assert body.key?("site_name")
    assert body.key?("categories")
    assert body.key?("tags")
    assert body["post_counts"].key?("total")
  end
end
