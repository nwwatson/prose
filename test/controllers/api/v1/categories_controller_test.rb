require "test_helper"

class Api::V1::CategoriesControllerTest < ActionDispatch::IntegrationTest
  def auth_header
    { "Authorization" => "Bearer prose_admin_test_token_1234567890abcdef" }
  end

  test "rejects requests without a token" do
    get "/api/v1/categories"
    assert_response :unauthorized
  end

  test "lists categories with post counts" do
    get "/api/v1/categories", headers: auth_header
    assert_response :success

    body = JSON.parse(response.body)
    names = body["categories"].map { |c| c["name"] }
    assert_includes names, "Technology"
    assert body["categories"].all? { |c| c.key?("post_count") }
  end
end
