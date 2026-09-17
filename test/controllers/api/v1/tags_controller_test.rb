require "test_helper"

class Api::V1::TagsControllerTest < ActionDispatch::IntegrationTest
  def auth_header
    { "Authorization" => "Bearer prose_admin_test_token_1234567890abcdef" }
  end

  test "lists tags with post counts" do
    get "/api/v1/tags", headers: auth_header
    assert_response :success

    body = JSON.parse(response.body)
    names = body["tags"].map { |t| t["name"] }
    assert_includes names, "Ruby"
  end

  test "creates a new tag" do
    assert_difference "Tag.count", 1 do
      post "/api/v1/tags", params: { name: "Testing" }, headers: auth_header
    end

    assert_response :created
    assert_equal "Testing", JSON.parse(response.body)["name"]
  end

  test "returns the existing tag when the name already exists" do
    assert_no_difference "Tag.count" do
      post "/api/v1/tags", params: { name: "Ruby" }, headers: auth_header
    end

    assert_response :created
    assert_equal tags(:ruby).id, JSON.parse(response.body)["id"]
  end
end
