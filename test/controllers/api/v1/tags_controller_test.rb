require "test_helper"

class Api::V1::TagsControllerTest < ActionDispatch::IntegrationTest
  test "lists tags with post counts" do
    get "/api/v1/tags", headers: api_auth_header
    assert_response :success

    body = JSON.parse(response.body)
    names = body["tags"].map { |t| t["name"] }
    assert_includes names, "Ruby"
  end

  test "creates a new tag" do
    assert_difference "Tag.count", 1 do
      post "/api/v1/tags", params: { name: "Testing" }, headers: api_auth_header
    end

    assert_response :created
    assert_equal "Testing", JSON.parse(response.body)["name"]
  end

  test "returns the existing tag when the name already exists" do
    assert_no_difference "Tag.count" do
      post "/api/v1/tags", params: { name: "Ruby" }, headers: api_auth_header
    end

    assert_response :created
    assert_equal tags(:ruby).id, JSON.parse(response.body)["id"]
  end
end
