require "test_helper"

class Api::V1::AssetsControllerTest < ActionDispatch::IntegrationTest
  test "uploads a base64-encoded file" do
    data = Base64.encode64("fake image content")

    post "/api/v1/assets", params: { filename: "test.jpg", data: data }, headers: api_auth_header
    assert_response :created

    body = JSON.parse(response.body)
    assert body["url"].present?
    assert_equal "test.jpg", body["filename"]
  end

  test "returns an error when neither file nor base64 data is provided" do
    post "/api/v1/assets", params: {}, headers: api_auth_header
    assert_response :unprocessable_entity
  end

  test "returns an error when file is a plain string instead of an upload" do
    post "/api/v1/assets", params: { file: "not-a-file" }, headers: api_auth_header
    assert_response :unprocessable_entity
  end
end
