require "test_helper"

class Api::V1::AssetsControllerTest < ActionDispatch::IntegrationTest
  def auth_header
    { "Authorization" => "Bearer prose_admin_test_token_1234567890abcdef" }
  end

  test "uploads a base64-encoded file" do
    data = Base64.encode64("fake image content")

    post "/api/v1/assets", params: { filename: "test.jpg", data: data }, headers: auth_header
    assert_response :created

    body = JSON.parse(response.body)
    assert body["url"].present?
    assert_equal "test.jpg", body["filename"]
  end

  test "returns an error when neither file nor base64 data is provided" do
    post "/api/v1/assets", params: {}, headers: auth_header
    assert_response :unprocessable_entity
  end
end
